# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Open `forceme.xcodeproj` in Xcode. Build: `Cmd+B`. Run on simulator: `Cmd+R`. No CLI build setup — Xcode only.

## App Overview

iOS SwiftUI app. Records voice, transcribes with WhisperKit on-device, reads result aloud with TTSKit. Stack: SwiftUI + ArgmaxOSS (WhisperKit, TTSKit, SpeakerKit). No SwiftData.

## Architecture

- `forcemeApp.swift` — entry point, root `VoiceLoopView`
- `SpeechEngine.swift` — `@MainActor @Observable` class owning both `WhisperKit` and `TTSKit` instances; drives `State` enum through the full record→transcribe→speak pipeline
- `VoiceLoopView.swift` — single-screen UI; hold-to-record gesture, reacts to `SpeechEngine.State`

`SpeechEngine` is created as `@State` in `VoiceLoopView` and loaded once via `.task`. Models download from HuggingFace on first run and are cached locally by ArgmaxOSS.

WhisperKit model in use: `openai_whisper-large-v3-v20240930_626MB` (best multilingual accuracy per Argmax recommendation). TTSKit model: `qwen3TTS_0_6b` (fast, runs on all devices).

## Code Style

- No comments. Names must be self-documenting.
- No abstraction layers until pattern repeats 3+ times.
- No view model boilerplate for simple views — `@Query` + `@Environment` directly in view.
- Minimalist UI: system fonts, system colors, generous whitespace. No decorative chrome.
- Pinterest-level visual quality: every screen must feel considered and calm.
- `withAnimation` on all data mutations.
- `#Preview` on every view.

## ArgmaxOSS Conventions

- `WhisperKit` and `TTSKit` are expensive to init — create once, reuse.
- Audio recorded at 16 kHz mono (WhisperKit's native rate) to avoid resampling overhead.
- `tts.play()` streams audio frame-by-frame; no need to save to disk.
- Adding SpeakerKit: init alongside WhisperKit, call `diarize(audioArray:)` then `diarization.addSpeakerInfo(to: transcription)` for speaker-attributed output.
