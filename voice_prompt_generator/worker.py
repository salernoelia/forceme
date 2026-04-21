import argparse
import os
import soundfile as sf
import torch
from qwen_tts import Qwen3TTSModel

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Qwen3 TTS Premade Voice Generation Worker")
    parser.add_argument("--speaker", default="Ryan", help="Speaker name (e.g., Ryan, Aiden, Vivian)")
    parser.add_argument("--text", default="Testing the internal speaker embedding.", help="Text to synthesize")
    parser.add_argument("--language", default="English", help="Language label")
    parser.add_argument("--output", default="output_premade.wav", help="Output WAV path")
    parser.add_argument("--max-new-tokens", type=int, default=300)
    parser.add_argument("--temperature", type=float, default=0.6)
    return parser.parse_args()

def main() -> None:
    args = parse_args()
    os.environ.setdefault("TORCHAUDIO_USE_SOX", "0")

    device = "mps" if torch.backends.mps.is_available() else "cpu"
    
    model = Qwen3TTSModel.from_pretrained(
        "Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice",
        device_map=device,
        dtype=torch.float32,
        attn_implementation="sdpa",
    )

    wavs, sr = model.generate_custom_voice(
        text=args.text,
        language=args.language,
        speaker=args.speaker,
        max_new_tokens=args.max_new_tokens,
        temperature=args.temperature,
    )

    sf.write(args.output, wavs[0], sr)
    print(f"Generated audio for {args.speaker} saved to {args.output}")

if __name__ == "__main__":
    main()
