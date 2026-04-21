I will first gather concrete codebase context around the review items and your existing design constraints, then I’ll produce a professional step-by-step implementation plan with commit checkpoints and persist it in a permanent tracker file. Since I’m currently in planning mode, I’ll fully plan now and prepare the execution-ready handoff structure next.I’m starting discovery with a focused read-only scan agent to map each review suggestion to concrete files/symbols and identify sequencing dependencies for checkpointed commits.

Map review items to codebase

Read [](file:///Users/eliasalerno/Github/tallyvity/reviews/review_1.md)

Read [](file:///Users/eliasalerno/Github/tallyvity/CLAUDE.md)

Searched for regex `func listen|VAD|silero|Voice Activity|maxDuration`, 20 results

Searched for regex `CADisplayLink|isIdleTimerDisabled`, 12 results

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity/SessionStore.swift)

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity/SessionEngine.swift#1-1), lines 1 to 100

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity/GemmaEngine.swift#1-1), lines 1 to 120

Searched for regex `roundEnd|photoDelta|qaPlayback|selfScore`, 20 results

Searched for regex `func .*round|generateDynamicVoiceLines|workStartPrompts`, 6 results

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity/SpeechEngine.swift#1-1), lines 1 to 80

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity/SessionReportView.swift)

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity/SessionEngine.swift#100-100), lines 100 to 351

Searched for regex `motivationSelection|photo|baseline|delta`, 20 results

Searched for regex `listen\(|recordingURL|transcribe`, 20 results

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity/GemmaPrompts.swift)

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity/SessionEngine.swift#150-150), lines 150 to 351

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity/SessionEngine.swift#100-100), lines 100 to 538

Searched for regex `MotivationSelector|ScoreSelector`, 6 results

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity/TimerRingView.swift)

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity/SessionEngine.swift#80-80), lines 80 to 538

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity/SpeechEngine.swift#100-100), lines 100 to 145

Searched for regex `wait(for|Score|Motivation|Photo)`, 7 results

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity)

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity/SessionEngine.swift#130-130), lines 130 to 560

Read [](file:///Users/eliasalerno/Github/tallyvity/tallyvity/FocusView.swift#1-1), lines 1 to 100

Created memory file [](file:///Users/eliasalerno/Library/Application%20Support/Code/User/workspaceStorage/c837693e830fffb58465c351ceeb46fc/GitHub.copilot-chat/memory-tool/memories/OWJhMDU2MjktM2RlZS00Y2JjLTlmNTgtYWM5NTliOWZkOTkw/tallyvity-mapping.md)

Read [](file:///Users/eliasalerno/Library/Application%20Support/Code/User/workspaceStorage/c837693e830fffb58465c351ceeb46fc/GitHub.copilot-chat/chat-session-resources/9ba05629-3dee-4cbc-9f58-ac959b9fd990/call_kQ8z6vW6j8VgUZhHGXMrAWGk__vscode-1776764434899/content.txt#1-1), lines 1 to 260

Discovery is complete and I’ve mapped the suggestions to concrete symbols and dependencies. Next I’ll align on scope and tracking preferences (critical/high/medium sequencing and issue-vs-local tracking), then finalize a commit-by-commit execution plan and persist it.

Analyzing your answers...

I have your preferences: Critical+High first, local tracker file, and one commit per review item. I’ll now persist a detailed execution plan in session memory and present the full professional checklist with commit checkpoints.

Read memory

Read memory

Created memory file [](file:///Users/eliasalerno/Library/Application%20Support/Code/User/workspaceStorage/c837693e830fffb58465c351ceeb46fc/GitHub.copilot-chat/memory-tool/memories/OWJhMDU2MjktM2RlZS00Y2JjLTlmNTgtYWM5NTliOWZkOTkw/plan.md)

## Plan: Tallyvity Critical+High Rollout

This is the professional execution plan, sequenced by dependency, with explicit commit checkpoints and a permanent local tracker. It preserves the current design guidelines in CLAUDE.md: minimalist UI, no unnecessary abstraction, calm/system visual language, and no behavior regressions.

### 1. Scope and Tracking Decisions
1. Implement Phase 1 as Critical + High items only from review_1.md.
2. Defer Medium items to a later phase.
3. Use one commit per review item.
4. Keep a permanent local ledger at specs/implementation_checkpoints.md as source of truth.

### 2. Commit Checkpoints (Step-by-Step)

1. `chore(tracking): add implementation checkpoint ledger`  
Create specs/implementation_checkpoints.md with:
- Item IDs (C1-C5, H1-H5)
- Acceptance criteria
- Status (`todo/in-progress/done`)
- Verification evidence notes

2. `feat(vad): integrate silero-based voice activity stop conditions`  
Primary touchpoints:
- SessionEngine.swift
- SpeechEngine.swift
- VAD model artifact under models  
Outcome: response capture auto-stops on sustained silence instead of fixed max-duration behavior.

3. `feat(session): add round-end recovery window before QA playback`  
Primary touchpoint:
- SessionEngine.swift  
Outcome: deterministic silent recovery buffer between timer end and first reflection question.

4. `feat(session): add low-motivation starter block and continuation prompt`  
Primary touchpoints:
- SessionEngine.swift
- FocusView.swift
- MotivationSelector.swift  
Outcome: motivation ≤ 2 triggers 5-minute starter, then yes/no continuation into normal flow.

5. `feat(session): add voice-based flow extension grace window`  
Primary touchpoint:
- SessionEngine.swift  
Outcome: 30-second post-timer window; “keep going/extend” adds +10 minutes without phase transition.

6. `perf(gemma): batch output publishing and reduce main-thread pressure`  
Primary touchpoint:
- GemmaEngine.swift  
Outcome: background accumulation, batched main-actor publish cadence (~200ms), smoother UI under load.

7. `feat(session): add phase checkpoint persistence and resume flow`  
Primary touchpoints:
- SessionEngine.swift
- SessionStore.swift
- FocusView.swift  
Outcome: recoverable mid-session state after force-quit/crash.

8. `fix(prompts): enforce own-name usage ceiling`  
Primary touchpoint:
- GemmaPrompts.swift  
Outcome: name usage constrained to memory recall + closing sentence only.

9. `feat(photo): add factual baseline-delta feedback integration`  
Primary touchpoints:
- SessionEngine.swift
- GemmaEngine.swift  
Outcome: neutral evidence statement only when visual delta confidence is sufficient; silent fallback otherwise.

10. `fix(timer): harden screen-awake behavior during active phases`  
Primary touchpoints:
- TimerRingView.swift
- SessionEngine.swift  
Outcome: stronger anti-sleep reliability during active timers/interruption scenarios.

11. `feat(memory): add semantic session retrieval pipeline`  
Primary touchpoint:
- SessionStore.swift  
Outcome: embedding-based similarity replaces lexical overlap for recall relevance.

12. `chore(release): close critical/high roadmap and document verification evidence`  
Update:
- specs/implementation_checkpoints.md
- review_1.md (optional status appendix only)  
Outcome: final verification signoff + deferred medium backlog explicitly listed.

### 3. Verification Gates (Must Pass Before Finalization)

1. End-to-end normal loop works with no UX regressions.
2. Low-motivation path behaves as designed (5-minute starter + continuation).
3. Flow-extension command succeeds within grace window.
4. VAD auto-stop works and avoids long silence capture.
5. Gemma generation does not visibly stutter timer/progress UI.
6. Force-quit recovery resumes from checkpointed phase.
7. Name ceiling rule holds across generated/spoken prompts.
8. Photo-feedback remains factual, never speculative.
9. Semantic retrieval matches lexically different but semantically similar goals.
10. Touched views remain aligned with CLAUDE.md design language.


Github/tallyvity/models  main ✗                                  7m ✖ ⚑ ◒  
▶ ls
config.json
model.safetensors
modules.json
silero-vad-unified-256ms-v6.0.0.mlmodelc
tokenizer.json
tokenizer_config.json
vocab.txt