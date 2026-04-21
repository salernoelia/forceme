import Foundation

enum GemmaPrompts {

    static func generateQuestions(goal: String) -> String {
        """
        The user is starting a 25-minute focused work session. Goal: "\(goal)"

        Output exactly 3 short review questions for end of session. One per line. No numbering. No extra text.
        Questions must be factual and neutral, not encouraging.
        Questions must NOT start with "What", "Hm", or "Um".

        Tell me what you actually finished.
        Name the main thing that got in the way.
        One change you'd make next time.

        Output only those three lines verbatim.
        """
    }

    static func createArtifact(goal: String, loops: [LoopRecord]) -> String {
        let summary = loops.enumerated().map { i, l in
            "Loop \(i+1) [score \(l.score)]: finished=\(l.answers.first ?? "unknown"). blocker=\(l.answers.count > 1 ? l.answers[1] : "none"). next=\(l.answers.count > 2 ? l.answers[2] : "none")"
        }.joined(separator: "\n")

        return """
        Extract facts from this work session. Output ONLY valid JSON, no other text, no markdown.

        Goal: \(goal)
        \(summary)

        Required JSON: {"blocker": "main friction in one short phrase", "intent_next": "user's stated next action in one short phrase"}
        """
    }

    static func closingSentence(name: String, goal: String, loops: [LoopRecord], blocker: String, intentNext: String) -> String {
        let avg = loops.isEmpty ? 0 : loops.map(\.score).reduce(0, +) / loops.count
        return """
        Write one factual closing sentence. No praise. No adjectives. No emotional framing. Specific facts only.

        Name: \(name)
        Goal: \(goal)
        Loops: \(loops.count)
        Average score: \(avg)/5
        Blocker: \(blocker)
        Next: \(intentNext)

        Pattern: "\(name), today you [loop count + goal fact]. [blocker fact]. [intent_next] is where to start next time."
        Output ONLY the sentence. Nothing else.
        """
    }

    static func memoryRecall(name: String, goal: String, relevant: [SessionArtifact]) -> String? {
        guard !relevant.isEmpty else { return nil }
        let history = relevant.map { "goal=\($0.goal) blocker=\($0.blocker) next=\($0.intentNext)" }.joined(separator: " | ")
        return """
        Write one short memory recall sentence. Reference past session if relevant. No filler words.

        User: \(name)
        Current goal: \(goal)
        Past sessions: \(history)

        If relevant: output "\(name), last time you worked on something similar, [specific past fact]."
        If NOT relevant: output only the word SKIP

        Output only the sentence or SKIP.
        """
    }
}
