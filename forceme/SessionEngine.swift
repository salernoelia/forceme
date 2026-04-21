import Foundation
import SwiftUI
import AVFoundation
import UIKit

@MainActor
@Observable
final class SessionEngine {

    enum Phase: Equatable {
        case idle
        case motivationSelection
        case preparingAudio
        case goalCapture
        case photoBaseline
        case backgroundPrep(loopNumber: Int)
        case workActive(loopNumber: Int)
        case roundEnd
        case photoDelta
        case qaPlayback(questionIndex: Int, loopNumber: Int)
        case selfScore(loopNumber: Int)
        case storing
        case breakTime(loopNumber: Int)
        case nextSessionCountdown(loopNumber: Int)
        case sessionReport
        case error(String)

        static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
              case (.idle, .idle), (.motivationSelection, .motivationSelection), (.preparingAudio, .preparingAudio), (.goalCapture, .goalCapture), (.photoBaseline, .photoBaseline),
                 (.roundEnd, .roundEnd), (.photoDelta, .photoDelta),
                 (.storing, .storing), (.sessionReport, .sessionReport): return true
            case (.backgroundPrep(let a), .backgroundPrep(let b)): return a == b
            case (.workActive(let a), .workActive(let b)): return a == b
            case (.qaPlayback(let q1, let l1), .qaPlayback(let q2, let l2)): return q1 == q2 && l1 == l2
            case (.selfScore(let a), .selfScore(let b)): return a == b
            case (.breakTime(let a), .breakTime(let b)): return a == b
            case (.nextSessionCountdown(let a), .nextSessionCountdown(let b)): return a == b
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    static let totalLoops = 4

    var workDuration: TimeInterval = 25 * 60
    var shortBreakDuration: TimeInterval = 5 * 60
    var longBreakDuration: TimeInterval = 20 * 60

    private(set) var phase: Phase = .idle
    private(set) var timerProgress: Double = 0
    private(set) var timerElapsed: TimeInterval = 0
    private(set) var currentGoal: String = ""
    private(set) var memoryRecallText: String? = nil
    private(set) var isRecording: Bool = false
    private(set) var transcript: String = ""
    private(set) var currentQuestion: String = ""
    private(set) var completedLoops: [LoopRecord] = []
    private(set) var finalArtifact: SessionArtifact? = nil
    private(set) var currentLoopAnswers: [String] = []

    private let speech: SpeechEngine
    private let gemma: GemmaEngine
    private let store = SessionStore.shared

    private var sessionTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    private var prerenderedQuestions: [String] = [
        "Tell me what you actually finished.",
        "Name the main thing that got in the way.",
        "One change you'd make next time."
    ]

    private var recordingStopped = false
    private var pendingPhoto: UIImage? = nil
    private var photoSkipped = false
    private var timerSkipped = false
    private var currentLoopNumber: Int = 0
    private var haptic = UIImpactFeedbackGenerator(style: .light)
    private var scoreContinuation: CheckedContinuation<Int, Never>?
    private var motivationContinuation: CheckedContinuation<Int, Never>?
    private var pendingScore: Int?
    private var pendingMotivation: Int?
    private var sessionMotivationLevel: Int?

    init(speech: SpeechEngine, gemma: GemmaEngine) {
        self.speech = speech
        self.gemma = gemma
    }

    // MARK: - Public API

    func startSession(userName: String) {
        sessionTask?.cancel()
        sessionTask = Task { [weak self] in
            await self?.runSession(userName: userName)
        }
    }

    func cancelSession() {
        sessionTask?.cancel()
        timerTask?.cancel()
        UIApplication.shared.isIdleTimerDisabled = false
        withAnimation { phase = .idle }
    }

    func stopListening() {
        recordingStopped = true
    }

    func skipPhase() {
        timerSkipped = true
    }

    func setBaselinePhoto(_ image: UIImage) {
        pendingPhoto = image
    }

    func skipPhoto() {
        photoSkipped = true
    }

    func dismissReport() {
        withAnimation {
            phase = .idle
            finalArtifact = nil
            completedLoops = []
            currentGoal = ""
            memoryRecallText = nil
            timerProgress = 0
            timerElapsed = 0
        }
    }

    func submitScore(_ score: Int) {
        if let continuation = scoreContinuation {
            scoreContinuation = nil
            continuation.resume(returning: score)
        } else {
            pendingScore = score
        }
    }

    func submitMotivation(_ level: Int) {
        if let continuation = motivationContinuation {
            motivationContinuation = nil
            continuation.resume(returning: level)
        } else {
            pendingMotivation = level
        }
    }

    func cancelError() {
        withAnimation { phase = .idle }
    }

    var isProcessingSpeech: Bool {
        switch speech.state {
        case .transcribing, .speaking, .loadingModels: return true
        default: return false
        }
    }

    // MARK: - Timer display helpers

    var remainingTime: TimeInterval {
        let total: TimeInterval
        switch phase {
        case .workActive, .backgroundPrep:
            total = workDuration
        case .breakTime(let n):
            total = n >= Self.totalLoops ? longBreakDuration : shortBreakDuration
        default:
            total = workDuration
        }
        return max(0, total - timerElapsed)
    }

    var isWorkPhase: Bool {
        if case .workActive = phase { return true }
        if case .backgroundPrep = phase { return true }
        return false
    }

    // MARK: - Session runner

    private func runSession(userName: String) async {
        guard !Task.isCancelled else { return }

        withAnimation { phase = .motivationSelection }
        let motivation = await waitForMotivation()
        guard !Task.isCancelled else { return }
        sessionMotivationLevel = motivation

        withAnimation { phase = .preparingAudio }
        let speechReady = await speech.ensureReady()
        guard speechReady else {
            withAnimation { phase = .error("Audio models are still unavailable. Please try again.") }
            return
        }

        completedLoops = []
        currentGoal = ""
        currentLoopNumber = 1
        pendingPhoto = nil
        photoSkipped = false
        memoryRecallText = nil
        finalArtifact = nil
        sessionMotivationLevel = motivation
        prerenderedQuestions = [
            "Tell me what you actually finished.",
            "Name the main thing that got in the way.",
            "One change you'd make next time."
        ]

        // Goal capture
        withAnimation { phase = .goalCapture }
        await say("Tell me your goal for today.")
        guard !Task.isCancelled else { return }
        let goal = await listen(maxDuration: 30)
        guard !Task.isCancelled, !goal.isEmpty else {
            withAnimation { phase = .idle }
            return
        }
        currentGoal = goal

        // Memory recall (non-blocking, runs concurrently on main actor)
        Task { [weak self] in
            guard let self else { return }
            let relevant = store.findRelevant(for: goal)
            if let prompt = GemmaPrompts.memoryRecall(name: userName, goal: goal, relevant: relevant) {
                await gemma.generate(prompt: prompt)
                let output = gemma.output.trimmingCharacters(in: .whitespacesAndNewlines)
                if output != "SKIP" && !output.isEmpty {
                    withAnimation { self.memoryRecallText = output }
                }
            }
        }

        // Background Gemma question generation
        Task { [weak self] in
            guard let self else { return }
            await gemma.generate(prompt: GemmaPrompts.generateQuestions(goal: goal))
            let output = gemma.output
            let qs = output.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            if qs.count >= 3 {
                prerenderedQuestions = Array(qs.prefix(3))
            }
        }

        // Photo baseline
        await say("Want to share a photo of what you are working on??")
        withAnimation { phase = .photoBaseline }
        _ = await waitForPhoto(timeout: 10)
        guard !Task.isCancelled else { return }

        // Begin work loop
        await runLoop()
    }

    private func runLoop() async {
        guard !Task.isCancelled else { return }

        withAnimation { phase = .backgroundPrep(loopNumber: currentLoopNumber) }

        await say("Let's go. 25 minutes.")
        UIApplication.shared.isIdleTimerDisabled = true
        phase = .workActive(loopNumber: currentLoopNumber)
        await runTimer(duration: workDuration)
        guard !Task.isCancelled else { UIApplication.shared.isIdleTimerDisabled = false; return }

        haptic.impactOccurred(intensity: 0.7)
        UIApplication.shared.isIdleTimerDisabled = false
        await runRoundEnd()
    }

    private func runRoundEnd() async {
        guard !Task.isCancelled else { return }

        withAnimation { phase = .roundEnd }
        await say("Good. Let's see where you got to.")
        guard !Task.isCancelled else { return }

        withAnimation { phase = .photoDelta }
        pendingPhoto = nil
        photoSkipped = false
        _ = await waitForPhoto(timeout: 8)
        guard !Task.isCancelled else { return }

        currentLoopAnswers = []
        for i in 0..<3 {
            guard !Task.isCancelled else { return }
            withAnimation { phase = .qaPlayback(questionIndex: i, loopNumber: currentLoopNumber) }
            withAnimation { currentQuestion = prerenderedQuestions[i] }
            await say(prerenderedQuestions[i])
            let answer = await listen(maxDuration: 30)
            currentLoopAnswers.append(answer)
        }

        guard !Task.isCancelled else { return }
        withAnimation { phase = .selfScore(loopNumber: currentLoopNumber) }
        await say("Score this round.")
        let score = await waitForScore()

        withAnimation {
            phase = .storing
            completedLoops.append(LoopRecord(
                goalText: currentGoal,
                answers: currentLoopAnswers,
                score: score,
                scoreReason: ""
            ))
        }

        guard !Task.isCancelled else { return }

        if completedLoops.count >= Self.totalLoops {
            await finishSession()
        } else {
            let breakLabel = completedLoops.count >= Self.totalLoops - 1 ? "20" : "5"
            await say("Stored. Rest for \(breakLabel) minutes.")
            currentLoopNumber += 1
            await runBreak()
        }
    }

    private func runBreak() async {
        guard !Task.isCancelled else { return }

        let isLong = completedLoops.count >= Self.totalLoops
        let duration = isLong ? longBreakDuration : shortBreakDuration

        guard duration > 0 else { await runLoop(); return }

        withAnimation { phase = .breakTime(loopNumber: currentLoopNumber) }
        await runTimer(duration: duration)
        guard !Task.isCancelled else { return }

        // Transition screen before next loop
        withAnimation { phase = .nextSessionCountdown(loopNumber: currentLoopNumber) }
        await say("Session \(currentLoopNumber) starting now.")
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }

        await runLoop()
    }

    private func finishSession() async {
        guard !Task.isCancelled else { return }
        withAnimation { phase = .storing }

        var blocker = ""
        var intentNext = ""

        await gemma.generate(prompt: GemmaPrompts.createArtifact(goal: currentGoal, loops: completedLoops))
        let artifactJSON = gemma.output
        if let data = artifactJSON.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            blocker = dict["blocker"] ?? ""
            intentNext = dict["intent_next"] ?? ""
        }

        let settings = SettingsStore()
        let name = settings.userName.isEmpty ? "there" : settings.userName

        await gemma.generate(prompt: GemmaPrompts.closingSentence(
            name: name, goal: currentGoal, loops: completedLoops,
            blocker: blocker, intentNext: intentNext
        ))
        let closing = gemma.output.trimmingCharacters(in: .whitespacesAndNewlines)

        let artifact = SessionArtifact(
            id: UUID().uuidString,
            date: Date(),
            goal: currentGoal,
            motivationLevel: sessionMotivationLevel,
            score: Double(completedLoops.map(\.score).reduce(0, +)) / Double(max(completedLoops.count, 1)),
            blocker: blocker,
            intentNext: intentNext,
            loopsCompleted: completedLoops.count,
            closingSentence: closing
        )
        store.save(artifact)
        withAnimation { finalArtifact = artifact }

        await say("That's the session.")
        try? await Task.sleep(for: .seconds(1))
        if !closing.isEmpty { await say(closing) }

        guard !Task.isCancelled else { return }
        withAnimation { phase = .sessionReport }
    }

    // MARK: - Timer

    private func runTimer(duration: TimeInterval) async {
        guard duration > 0, !Task.isCancelled else { return }

        timerElapsed = 0
        timerProgress = 0
        timerSkipped = false

        let clock = ContinuousClock()
        let start = clock.now

        while true {
            guard !Task.isCancelled else { return }  // cancel → do NOT set progress = 1
            guard !timerSkipped else { break }       // skip  → fall through to set progress = 1

            let d = clock.now - start
            let elapsed = Double(d.components.seconds) + Double(d.components.attoseconds) * 1e-18
            timerElapsed = min(elapsed, duration)
            timerProgress = min(elapsed / duration, 1.0)

            // 5-min haptics (only meaningful for work timers ≥ 5 min)
            if duration >= 300 {
                let prevElapsed = max(0, elapsed - 0.15)
                if Int(elapsed / 300) > Int(prevElapsed / 300) && elapsed > 1 {
                    haptic.impactOccurred(intensity: 0.25)
                }
            }

            if timerProgress >= 1.0 { break }

            do {
                try await Task.sleep(for: .milliseconds(150))
            } catch {
                return  // CancellationError → hard exit, do NOT complete timer
            }
        }

        // Only reached on natural finish or skip — not on cancel
        timerProgress = 1.0
        timerElapsed = duration
    }

    // MARK: - Audio helpers

    private func say(_ text: String) async {
        guard !text.isEmpty, !Task.isCancelled else { return }
        await speech.speak(text: text)
    }

    private func listen(maxDuration: TimeInterval) async -> String {
        recordingStopped = false
        withAnimation {
            isRecording = true
            transcript = ""   // clear stale text before each new capture
        }
        try? speech.startRecording()

        let deadline = Date().addingTimeInterval(maxDuration)
        while !Task.isCancelled && !recordingStopped && Date() < deadline {
            try? await Task.sleep(for: .milliseconds(100))
        }

        withAnimation { isRecording = false }
        let text = await speech.transcribeRecording()
        withAnimation { transcript = text }
        return text
    }

    private func waitForPhoto(timeout: TimeInterval) async -> UIImage? {
        let deadline = Date().addingTimeInterval(timeout)
        pendingPhoto = nil
        photoSkipped = false
        while !Task.isCancelled && !photoSkipped && Date() < deadline {
            if let photo = pendingPhoto { return photo }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return pendingPhoto
    }

    // MARK: - Helpers

    private func waitForScore() async -> Int {
        if let pendingScore {
            self.pendingScore = nil
            return pendingScore
        }
        return await withCheckedContinuation { cont in
            scoreContinuation = cont
        }
    }

    private func waitForMotivation() async -> Int {
        if let pendingMotivation {
            self.pendingMotivation = nil
            return pendingMotivation
        }
        return await withCheckedContinuation { cont in
            motivationContinuation = cont
        }
    }
}
