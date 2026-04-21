# Tallivity / FocusProof — Clinical Review & Implementation Roadmap

**Reviewed by:** Cognitive-Behavioral Psychology, UX, Pedagogy
**Scope:** Existing codebase (`forceme`), psychology assessment, FocusProof specification
**Standard:** Scientifically grounded, motivationally optimal Pomodoro intervention

---

## What Is Scientifically Sound — Keep Without Changes

**Vocal goal declaration.** The Production Effect (MacLeod et al., 2010) is well-replicated. Speaking a goal encodes it more deeply than typing and constitutes a behavioral contract. `goalCapture` is correctly implemented.

**Three-question metacognitive loop.** Zimmerman's (2002) self-regulation model validates exactly this structure — completion, obstacle, adaptation. Do not reduce or simplify these.

**Motivation labeling before session.** Emotional labeling reduces cognitive dissonance at task initiation (Torre & Lieberman, 2018). The 1–5 selector is appropriately designed and correctly pre-task.

**Strict local processing.** Privacy is not a UX nicety — it is a prerequisite for honest self-reporting. Users admitted failures more accurately in local-only conditions. This is non-negotiable and correctly implemented.

**Neutral, factual closing sentence.** Consistent with the Progress Principle (Amabile & Kramer, 2011) and SDT-aligned (Deci et al., 1999). The `GemmaPrompts.closingSentence` constraint — no praise, no adjectives — is correct and should not be softened.

**Past session recall at session start.** Spaced retrieval and contextual memory cueing are supported by Ebbinghaus and subsequent retrieval practice literature. The `findRelevant` + `memoryRecall` pipeline is correctly conceived.

---

## Critical — Must Fix Before Shipping

### 1. Ego Depletion at Round End

The current architecture piles three cognitively demanding tasks onto the highest-fatigue moment of the session: photo capture, three reflective questions, and a self-score. This is precisely when willpower resources are most depleted (Baumeister et al., 1998). The behavioral consequence is predictable: abandonment.

**Fix:** Pre-render all questions during the work phase (already partially done). Add a 10-second recovery buffer — one silent breath — before the first question plays. The voice line "Good. Let's see where you got to." performs this function only if there is genuine silence after it. Confirm in implementation that TTS playback of Question 1 does not begin until at least 8 seconds after the timer ends.

### 2. No Adaptive Behavior on Motivation Score

The app correctly captures motivation level but then does nothing with it. This is a significant waste of a valid psychometric input. A user selecting "1 — Low" should receive a structurally different first loop.

**Fix:** If motivation ≤ 2, offer a 5-minute starter block ("5-Minute Rule," Gollwitzer, 1999 — task initiation anxiety is the barrier, not willpower). After 5 minutes, silently ask via a single yes/no voice prompt whether to continue to 25. Do not restart the session. Do not explain the mechanism to the user.

### 3. Rigid Timer Fractures Flow States

The current implementation has no mechanism for a user in deep flow to signal continuity. Csikszentmihalyi's Flow research is unambiguous: forced interruption at a fixed interval is counterproductive when the user is engaged. The app currently provides only a "Skip" button, which skips the phase — not what a flow-state user needs.

**Fix:** When the work timer completes, play the end chime but do not immediately transition. Give the user a 30-second grace window during which a single voice command — "Keep going" or "Extend" — adds 10 minutes without any phase change. If no command is received, proceed normally. This is a minimal implementation change with significant psychological impact.

### 4. No Voice Activity Detection

The `listen()` function runs for a full `maxDuration` with no silence detection. This means the system records ambient noise indefinitely if the user doesn't tap "Done," and the transcript quality degrades. Whisper performance on long silences is poor.

**Fix:** Integrate Silero VAD (CoreML conversion) as a pre-processing gate. The FocusProof spec correctly identifies this. It is not optional — it directly affects transcription quality for every user response.

### 5. Gemma Inference Blocking Main Thread Risk

`GemmaEngine.generate()` is `@MainActor`. While the heavy computation is async, the output publishing path runs on the main actor and the observable state updates block SwiftUI layout passes. Under thermal throttling (loop 3+), this will produce visible UI stuttering.

**Fix:** Move Gemma output accumulation to a background actor. Publish batched updates to `@MainActor` on a 200ms cadence, not on every token. This is an architectural change but a necessary one.

---

## High Priority — Implement in First Release

### 6. No Crash Recovery

`SessionEngine` holds all state in memory. A crash at loop 3 destroys everything. For a 100-minute session, this is a critical reliability failure.

**Fix:** Persist phase state to disk on every transition. The FocusProof spec calls this out correctly. Use a simple JSON file — not SQLite for this purpose, as the state is a single object.

### 7. The Own-Name Effect Is Being Squandered

The app currently uses the user's name in the closing sentence only. Carmody & Lewis (2006) document a strong attentional response to hearing one's own name — but habituation is rapid. The design should strategically deploy this exactly twice per session: once at memory recall (session start) and once in the closing sentence (session end). The current code does not enforce this ceiling.

**Fix:** Audit all prompt templates. The name must not appear in question prompts, score prompts, or break prompts. Add a lint-style check in `GemmaPrompts` that flags any prompt template containing `\(name)` outside the two permitted locations.

### 8. Photo Pipeline Has No Functional Feedback Loop

Photos are captured and stored, but Gemma does not currently compare baseline to delta in any user-facing way. The professor's assessment correctly identifies this as a missed opportunity. The camera feature is currently functioning as a psychological placebo — it induces accountability through the Hawthorne effect alone, but delivers no information back to the user.

**Fix (minimum viable):** After the delta photo is captured, Gemma performs a diff against baseline. If visual change is detected, the Q&A prompt "What did you actually finish?" is accompanied by a factual observation: "I can see change in your workspace from where you started." This is not praise — it is evidence. If no baseline exists or Gemma cannot determine a difference, it remains silent. Never hallucinate a judgment.

### 9. Screen Staying Awake Is Not Legally Guaranteed

`UIApplication.shared.isIdleTimerDisabled = true` is the current approach. This is correct but insufficient — it doesn't survive audio session interruptions or background transitions. The FocusProof spec correctly identifies CADisplayLink as the robust mechanism.

**Fix:** Implement CADisplayLink in `TimerRingView` for the animation tick, which legally prevents sleep via active rendering. Keep `isIdleTimerDisabled` as a secondary guard. This is a correctness issue, not a polish issue.

### 10. Missing: Semantic Session Retrieval

`SessionStore.findRelevant()` currently uses word overlap (bag-of-words intersection). This will fail for semantically similar but lexically different goals: "finish quarterly report" and "complete Q3 writeup" return zero overlap. The memory recall feature is architecturally present but effectively non-functional for real usage.

**Fix:** Implement MiniLM-L6 via CoreML conversion for session embedding. Cosine similarity on embeddings. This is ~25MB model weight, justified by the psychological value of accurate memory retrieval.

---

## Medium Priority — Target Second Release

### 11. Break UX Is Behaviorally Empty

The break timer is a countdown with "Rest" text. Attention Restoration Theory (Kaplan, 1995) specifies that genuine restoration requires perceptual fascination with low-effort stimuli — not a blank screen. The current break experience is neutral at best, anxiety-inducing at worst (watching time pass).

**Fix:** During break, show a minimal ambient visual — a slow gradient, not gamified. Disable all interactive elements. Play one optional TTS suggestion drawn from a pre-recorded set: "Step away from the screen." "Look at something far away for 60 seconds." These are evidence-based rest cues, not motivational filler.

### 12. Missing: Pre-Recorded Human Voice for Fixed Prompts

The FocusProof spec correctly distinguishes fixed prompts (which should be human-recorded) from dynamic content (TTS). All fixed prompts in the current implementation go through TTS, which introduces latency and prosodic inconsistency. "Let's go. 25 minutes." should play in under 100ms, with natural human rhythm.

**Fix:** Record 7 fixed voice lines once. Store as compressed audio assets. TTS handles only: memory recall, questions, closing sentence. Pre-recorded handles: everything else.

### 13. Loop Count Is Hardcoded at 4

`SessionEngine.totalLoops = 4` is a constant. There is no scientific basis for exactly 4 loops being universally optimal. User cognitive capacity, session duration, and goal type all modulate the appropriate number.

**Fix:** Make total loops configurable at session start alongside the existing duration picker. Default 4, range 1–6. This is a 20-line change.

### 14. No Notification Architecture

The app has no re-engagement mechanism. The FocusProof spec outlines a scientifically grounded three-notification system. The key discipline is in what to exclude: no streaks, no badges, no daily nagging. Only three types — time-anchored work cue, fresh-start cue (Monday/month start), and a single lapse-recovery nudge after exactly 2 missed days, then silence.

This matters because the Fresh Start Effect (Dai et al., 2014) and Implementation Intentions (Gollwitzer, 1999) are among the most actionable findings in behavioral science for habit formation.

---

## What Should Be Rethought or Removed

### Remove: The `forceme` Internal Framing

This is not about naming convention. Self-Determination Theory (Deci & Ryan, 1985) is explicit: systems that frame themselves as coercive — even internally — leak this orientation into design decisions. The "Skip →" button label, the rigid loop enforcement, the mandatory question sequence — these all reflect a coercive design philosophy that is at odds with the autonomy component of SDT. Rename the package. More importantly, audit every forced interaction and ask whether it serves the user or the system's idea of what the user should do.

### Remove: Motivational Filler in Voice Lines

`generateDynamicVoiceLines` produces lines like "Lets ease into {minutes} of progress." and "Take it steady for {minutes}." These are exactly the kind of vague, tonally inconsistent AI-generated filler that erodes trust over repeated sessions. Users are not fooled by synthetic encouragement — they recognize it within days and begin ignoring all voice output, including the functional prompts.

**Rethink:** Fixed pre-recorded human lines for all non-dynamic content. Gemma generates only semantically specific content tied to the user's actual goal and actual session data. If Gemma cannot add specificity, it should say nothing.

### Remove: `LLMDemoView` from Production Build

The Gemma chat interface exposed via Settings → Diagnostics is a development tool, not a user-facing feature. It should be behind a debug flag, not accessible in production. Exposing the raw LLM to users frames the app as an AI toy, which undermines the behavioral intervention framing.

### Rethink: Photo as Mandatory UX Touchpoint

Currently, both baseline and delta photo prompts are visible UI states that the user must actively skip. This inverts the correct default. The photo should be silently available but never foregrounded as a required decision. If the user has previously skipped photos three times consecutively, the prompt should stop appearing entirely until the user re-enables it in Settings.

### Rethink: The Score Prompt Verbal Design

`"Score this round"` with a 1–5 circle selector is correct in principle. The spoken prompts, however, include lines like `"Quick score: how well did {goal} go?"` — which is evaluative framing. Behavioral self-assessment research (Zimmerman, 2002) shows that neutral, behavioral anchors produce more accurate and useful self-assessments than quality-framing ("how well").

**Replace with:** "Rate your output this round. 1 to 5." The distinction is small but produces meaningfully different self-assessments over time — output-based rather than effort-based, which is what the artifact data should contain.

---

## Not Needed — Do Not Build

**Streaks.** Not supported by SDT. Creates anxiety-driven compliance, not motivation. Explicitly excluded in FocusProof spec. Correct.

**Badges or points.** Extrinsic reward undermines intrinsic motivation for cognitively complex tasks (Deci et al., 1999). Correct to exclude.

**Daily notification reminders.** Notification fatigue is documented (Oulasvirta et al., 2012). More than one notification type per day, or notifications on consecutive days without behavioral change, produce negative engagement outcomes. The three-notification model in FocusProof is the ceiling, not a starting point.

**Real-time Gemma analysis during work phase.** Thermally irresponsible and psychologically unnecessary. Gemma infers once per phase boundary. Continuous inference serves no user need and introduces reliability risk.

---

## Priority Summary

| Urgency | Item |
|---|---|
| **Critical** | Ego depletion at round end · Adaptive motivation response · Flow extension command · VAD implementation · Main thread risk |
| **High** | Crash recovery · Own-name ceiling · Photo feedback loop · Screen-awake reliability · Semantic session retrieval |
| **Medium** | Break UX restoration · Pre-recorded human voice · Configurable loop count · Notification architecture |
| **Remove** | `forceme` coercive framing · AI filler voice lines · LLMDemoView in production · Foregrounded photo prompts · Quality-framing score prompts |
| **Do not build** | Streaks · Badges · Daily reminders · Continuous inference |

---

*The app's conceptual architecture is sound. The psychology is largely correct. The failures are in execution details that compound across a 100-minute session — small friction at loop 1 becomes abandonment by loop 3. Fix the critical items first. Everything else is refinement.*
