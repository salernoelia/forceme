# Tallyviity — Complete Implementation Plan

-----

## Scientific Foundations

| Principle                  | Source                           | Application                                                      |
| -------------------------- | -------------------------------- | ---------------------------------------------------------------- |
| Implementation intentions  | Gollwitzer, 1999                 | Goal declaration + notification cue design                       |
| Ultradian rhythm           | Kleitman, 1963                   | 25/5 work-rest structuring                                       |
| Output-based monitoring    | Amabile, 1993                    | Visual delta as work evidence                                    |
| Structured self-assessment | Zimmerman, 2002                  | Self-score beats external judgment                               |
| Spaced memory retrieval    | Ebbinghaus curve                 | Past session recall at session start                             |
| Reactance minimisation     | Brehm, 1966                      | No mid-session interruptions, ever                               |
| Cognitive offloading       | Risko & Gilbert, 2016            | Gemma holds history so user doesn’t have to                      |
| Attention restoration      | Kaplan, 1995                     | Genuine rest break UX, not just a timer                          |
| Own-name effect            | Carmody & Lewis, 2006            | Selective attention via name in TTS — sparse use only            |
| Progress principle         | Amabile & Kramer, 2011           | Specific factual closing sentence drives next-session motivation |
| Fresh start effect         | Dai, Loewenstein & Milkman, 2014 | Notifications anchored to temporal landmarks                     |
| SDT / intrinsic motivation | Deci & Ryan, 1985                | No streaks, no badges, no extrinsic reward mechanics             |

-----

## Full Session Flow

### Pre-Session (< 30 seconds)

```
APP OPEN
  → [Pre-recorded voice] "What are you working on today?"
  → [Whisper] captures goal declaration
  → [Pre-recorded voice] "Want to share a photo of where you are?"
  → [Optional] camera capture → stored as baseline artifact
  → [Pre-recorded voice] "Let's go. 25 minutes."
  → Timer starts
```

Gemma immediately begins background processing:

- Compress goal declaration into semantic artifact (< 50 tokens)
- Retrieve 2–3 most relevant past sessions via embedding similarity
- Inject into context: generate 3 questions for end-of-round
- TTS pre-renders all 3 questions as audio files
- Memory recall prompt prepared if relevant history exists

**Nothing is shown to user during this. Timer runs. Full silence.**

-----

### Work Phase (25 minutes)

```
FLUID TIMER ANIMATION (screen stays awake)
  → No interruptions
  → No notifications
  → Background: Gemma inference complete, TTS ready
  → At 20min mark: optional photo capture silently queued
```

Timer animation principles:

- Circular progress ring, slow breathing pulse at centre
- Colour shifts gradually warm → cool as time passes (no jarring changes)
- Single ambient haptic at 5-minute marks only
- **No countdown numbers visible** — removes anxiety, keeps focus

-----

### End-of-Round UX (Break — 5 minutes)

This is the critical UX moment. Nothing waits. Everything is pre-built.

```
TIMER COMPLETES
  → [Pre-recorded voice] "Good. Let's see where you got to."
  → [Optional prompt] "Share a photo if you want to."
    → If shared: Gemma diffs baseline → current silently
    → If skipped: proceed immediately
  → [Pre-rendered TTS, Question 1] plays automatically
  → [Whisper VAD] listens, captures answer
  → [Pre-rendered TTS, Question 2] plays
  → [Whisper] captures
  → [Pre-rendered TTS, Question 3] plays
  → [Whisper] captures
  → [Pre-recorded voice] "Score this round. 1 to 5."
  → [Whisper] captures score + optional spoken reason
  → [Pre-recorded voice] "Stored. Rest for 5 minutes."
```

**Total user wait time at any point: zero.** Everything pre-rendered.

Questions are generic by design:

- “What did you actually finish?”
- “What got in the way?”
- “What would you do differently?”

-----

### Multi-Loop Structure

```
LOOP 1 [25 work / 5 break+QA]
LOOP 2 [25 work / 5 break+QA]
LOOP 3 [25 work / 5 break+QA]
LOOP 4 [25 work / 20 LONG BREAK + FULL REPORT]
```

After loop 4 (or on user command: “finish session”):

- Full session report generated
- User optionally exports photo evidence strip
- Self-scores aggregated
- Memory artifacts written to store

-----

### Session Report

Delivered by TTS, shown on screen simultaneously:

```
SESSION SUMMARY
  Duration: N loops
  Your scores: [loop scores]
  What you said got in the way: [extracted from Q&A]
  Delta evidence: [thumbnail strip of baseline → final]
  Gemma summary: [2–3 sentences, user's own words reframed]
```

**No grade inflation. No encouragement language. Neutral mirror.**

-----

## Name Personalisation

### Scientific Basis

The own-name effect (Carmody & Lewis, 2006) is real and neurologically distinct — hearing your own name activates unique attentional processing. **However**, habituation is rapid. Overuse within minutes eliminates the effect entirely. Rule: **name used maximum twice per session**, at the two highest-attention moments only.

### Where Name Appears

|Moment                        |Example                                           |Why here                                            |
|------------------------------|--------------------------------------------------|----------------------------------------------------|
|Memory recall (session start) |*”[Name], last time you worked on this you said…”*|Signals personal relevance, not generic             |
|Closing sentence (session end)|*”[Name], today you…”*                            |Attention peak at completion, drives memory encoding|

Nowhere else. Not mid-session. Not in questions. Not in score prompts.

### Name in System Prompts

User first name stored at onboarding (voice input, Whisper captured). Injected as a literal string into:

- Memory recall Gemma prompt template
- Closing sentence Gemma prompt template
- Notification body text

Never in: question generation prompts, delta diff prompts, artifact writing prompts. Those are functional — name adds noise, not signal.

-----

## Closing Sentence

### Scientific Basis

The Progress Principle (Amabile & Kramer, 2011) is among the most replicated findings in work motivation: **documenting specific small wins** has measurable positive effect on next-session motivation and persistence. Generic praise does the opposite for intrinsically motivated people — it signals the external locus of evaluation and undermines autonomy (Deci et al., 1999).

The closing sentence must therefore be:

- **Specific** — drawn from actual session data, not templated praise
- **Factual** — what was objectively done, not how good it was
- **Forward-linking** — connect to the user’s own stated next intent

### Format

Gemma generates this from: session artifact + loop scores + user’s own Q&A answers. TTS reads it aloud. It appears on screen simultaneously.

> *”[Name], today you completed 3 loops on [goal]. You identified [blocker from Q&A] as the main friction. You said you’d [intent_next]. That’s where to start next time.”*

No adjectives. No “great”. No emotional framing. The specificity is the reward.

If session was low-scoring, the sentence still doesn’t editorialize:

> *”[Name], one loop completed on [goal]. You scored it [score]. You said [blocker]. [intent_next] is queued for next time.”*

Gemma prompt for this is tightly constrained — temperature 0, strict output format, no filler language allowed.

-----

## Notification Nudges

### What Science Actually Supports

**Included:**

|Mechanism                |Basis                                       |Implementation                                              |
|-------------------------|--------------------------------------------|------------------------------------------------------------|
|Time-anchored cue        |Implementation intentions (Gollwitzer, 1999)|Notification at user-declared work start time               |
|Fresh start effect       |Dai et al., 2014                            |Monday morning nudge + first of month                       |
|Re-engagement after lapse|Lapse recovery research (Sniehotta et al.)  |One nudge after 2 consecutive missed days — then silence    |
|Contextual specificity   |Habit stacking (Fogg, 2009)                 |Notification references their last session goal, not generic|

**Explicitly excluded (anti-patterns with evidence):**

|Mechanism               |Why excluded                                                                                                              |
|------------------------|--------------------------------------------------------------------------------------------------------------------------|
|Streaks                 |Creates anxiety not motivation; users work to protect streak not accomplish goals (see Duolingo streak anxiety literature)|
|Badges / points         |Extrinsic reward undermines intrinsic motivation (Deci & Ryan SDT, 1985)                                                  |
|Variable-schedule nudges|Operant conditioning / Skinner — manipulative, not supportive                                                             |
|Daily reminders         |Notification fatigue; engagement drops sharply beyond 1/day (Oulasvirta et al., 2012)                                     |
|Generic body text       |“Don’t forget to focus!” — ignored within days; no behavioural effect                                                     |

### Notification Types (3 only)

**1. Work Window Nudge** — daily, at user-set time

> *”[Name] — you said you work best at this time. [Last goal] is waiting.”*
> Requires: user declares preferred work time at onboarding. Adjusts automatically if user consistently opens app at a different time (sliding 7-day median).

**2. Fresh Start Nudge** — Monday 08:00 + 1st of month

> *“New week. [Name], last session you wanted to [intent_next].”*
> Only fires if user hasn’t already opened app that morning. One per trigger event, never both on same day.

**3. Re-engagement Nudge** — fires once after exactly 2 missed days

> *”[Name], it’s been a couple of days. [Last goal] is still there when you’re ready.”*
> After this fires once: **silence until user opens app.** No escalating reminders. No guilt.

### Notification Rules

- Maximum 1 notification per day, across all types
- User can silence any type individually at onboarding
- No notification fires during declared work hours of other apps (respect iOS Focus modes)
- All notification copy generated once at onboarding + updated after each session — never real-time LLM generation for notifications

-----

## Memory Architecture

### Two-Tier Storage

```
/sessions/
  raw/
    session_2026-04-21.json    ← full transcript, images, scores
  artifacts/
    session_2026-04-21.emb    ← compressed semantic vector
    session_2026-04-21.txt    ← Gemma summary (< 100 tokens)
```

**Artifact format (what Gemma writes after each session):**

```json
{
  "goal": "write section 2 of report",
  "phase_type": "writing",
  "time_of_day": "morning",
  "score": 2,
  "blocker": "kept rewriting same paragraph",
  "intent_next": "set word count target first",
  "delta_detected": true,
  "loops_completed": 3,
  "closing_sentence": "Name, today you completed 3 loops..."
}
```

This is what gets retrieved. Raw session stored separately, never loaded into context.

### Retrieval at Session Start

- Embed new goal declaration → cosine similarity against artifact embeddings
- Return top 2–3 matches
- Gemma receives: new goal + past artifacts → generates memory recall prompt if relevant
- If no relevant history: silent, no recall

-----

## Technical Architecture

### iOS Native Stack

|Layer           |Technology                                    |Reason                                   |
|----------------|----------------------------------------------|-----------------------------------------|
|UI              |SwiftUI                                       |Native animations, display link for timer|
|Audio session   |AVAudioSession (.playAndRecord, mixWithOthers)|Background audio survival                |
|STT             |WhisperKit (you have it)                      |On-device, proven                        |
|VAD             |Silero VAD via CoreML                         |Prevents Whisper running on silence      |
|LLM + Vision    |Gemma 4 2B via MediaPipe or llama.cpp         |On-device multimodal                     |
|TTS             |Your local TTS                                |Already have it                          |
|Embeddings      |MiniLM-L6 via CoreML conversion               |< 30MB, fast, on-device                  |
|Storage         |SQLite (raw) + binary flatfile (embeddings)   |Simple, no ORM overhead                  |
|Background tasks|BGTaskScheduler + BGProcessingTask            |Gemma inference during work phase        |
|Screen-on       |CADisplayLink in timer view                   |Keeps display active legally             |
|Camera          |AVCaptureSession                              |Baseline + end-of-round capture          |

### Concurrency Model

```
Main Thread:     UI, animation, audio playback
Background Q1:   Gemma inference (question generation, delta diff, artifact writing)
Background Q2:   TTS pre-rendering
Audio Q:         Whisper VAD + capture
```

Gemma runs exactly once per phase boundary — not continuously. Thermal budget is preserved.

### State Machine

```
IDLE
  → GOAL_CAPTURE (Whisper listening)
  → PHOTO_BASELINE (optional)
  → BACKGROUND_PREP (Gemma + TTS generating)
  → WORK_ACTIVE (timer running, background processing)
  → ROUND_END (pre-recorded line plays)
  → PHOTO_DELTA (optional)
  → QA_PLAYBACK (pre-rendered questions, Whisper captures)
  → SELF_SCORE (Whisper captures)
  → STORING (Gemma writes artifact, raw stored)
  → BREAK (rest timer, no AI)
  → [next loop GOAL_CAPTURE or SESSION_END]
```

Every state transition is crash-recoverable — state persisted to disk on each change.

### Pre-Recorded Voice Lines (human voice, not TTS)

|Trigger      |Line                               |
|-------------|-----------------------------------|
|Session start|“What are you working on today?”   |
|Photo prompt |“Want to share a photo?”           |
|Work start   |“Let’s go. 25 minutes.”            |
|Round end    |“Good. Let’s see where you got to.”|
|Score prompt |“Score this round. 1 to 5.”        |
|Break start  |“Rest. Back in 5.”                 |
|Session end  |“That’s the session.”              |

TTS handles: memory recall, questions, session report (dynamic content).
Pre-recorded handles: all fixed prompts (zero latency, better prosody).

-----

## UX Principles (Non-Negotiable)

1. **User never waits.** All Gemma inference happens during work phase. Playback is instant.
2. **No mid-session interruptions.** Ever. Science is clear on this.
3. **Phone stays awake** via CADisplayLink — timer animation is the legal mechanism.
4. **Voice-first throughout.** No typing required at any point.
5. **Photo always optional.** Never block a loop on missing photo.
6. **Report is neutral.** No “great job”, no score padding.
7. **Consecutive loops are seamless.** No app re-navigation between loops.
8. **Gemma abstains** if confidence is low rather than hallucinating a judgment.

-----

## What You Have vs. What to Build

|Have                 |Build                                                    |
|---------------------|---------------------------------------------------------|
|Whisper              |Silero VAD wrapper                                       |
|Gemma 4 2B multimodal|Prompt templates (goal → questions → artifact)           |
|Local TTS            |TTS pre-render queue manager                             |
|Basic pipeline       |Full state machine with crash recovery                   |
|—                    |MiniLM CoreML conversion + cosine retrieval              |
|—                    |SQLite session store + artifact store                    |
|—                    |CADisplayLink timer with breathing animation             |
|—                    |BGProcessingTask scheduler for Gemma                     |
|—                    |Pre-recorded voice line set (record once)                |
|—                    |Image preprocessing (contrast/binarise before delta diff)|
|—                    |Session report renderer (TTS + visual)                   |

-----

## Build Order (Strict)

1. State machine + crash recovery
2. Audio session (VAD → Whisper → TTS queue)
3. Timer UI with CADisplayLink
4. Gemma prompt templates (test offline first)
5. Storage (SQLite raw + artifact JSON)
6. MiniLM embedding + retrieval
7. BGProcessingTask scheduler
8. Camera pipeline + image preprocessing
9. Pre-recorded voice lines
10. Session report view
11. Multi-loop sequencing
12. End-to-end integration test (full 4-loop session)

-----

## Known Hard Problems

**Lighting variance** will break delta detection before Gemma sees anything. Solve with: histogram normalisation + contrast stretching before diff, not after.

**Gemma 2B hallucinating on ambiguous Q&A answers.** Solution: binary pass/fail only on clear cases; abstain and flag otherwise. Never force a score.

**Thermal throttling after loop 3.** Gemma inference must be spaced — never two inferences within 3 minutes. Schedule BGProcessingTask at minute 5 of work phase, not at loop start.

**VAD false triggers** on ambient noise will interrupt Whisper incorrectly. Silero VAD threshold must be tuned per environment — expose as hidden debug setting.

-----

*All data local. No telemetry. Session export: PDF only, user-initiated.*