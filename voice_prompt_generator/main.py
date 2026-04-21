import json
import os
import argparse
import subprocess

def parse_args():
    parser = argparse.ArgumentParser(description="Batch generate audio from prompts.json")
    parser.add_argument("--json", default="tallyvity/prompts.json", help="Path to prompts.json")
    parser.add_argument("--speaker", help="Speaker name (if omitted, all voices will be generated)")
    parser.add_argument("--output-dir", default="tallyvity/Assets/Audio", help="Base output directory for audio files")
    parser.add_argument("--force", action="store_true", help="Overwrite existing files")
    return parser.parse_args()

def main():
    args = parse_args()
    
    VOICES = {
        "Ryan": "Ryan",
        "Aiden": "Aiden",
        "OnoAnna": "Ono-Anna",
        "Sohee": "Sohee",
        "Eric": "Eric",
        "Dylan": "Dylan",
        "Serena": "Serena",
        "Vivian": "Vivian",
        "UncleFu": "Uncle-Fu"
    }

    if not os.path.exists(args.json):
        print(f"Error: {args.json} not found.")
        return

    with open(args.json, "r") as f:
        data = json.load(f)

    voice_prompts = data.get("voice_prompts", {})
    to_generate = []

    for key, value in voice_prompts.items():
        if isinstance(value, dict):
            cue = value.get("cue")
            fallback = value.get("fallback") or value.get("text")
            if cue and fallback:
                to_generate.append((cue, fallback))
        elif isinstance(value, str) and key == "extension_added":
             to_generate.append((key, value))

    speakers = [args.speaker] if args.speaker else VOICES.keys()

    for speaker_key in speakers:
        speaker_name = VOICES.get(speaker_key, speaker_key)
        # Create a speaker-specific subdirectory to keep things organized
        speaker_dir = os.path.join(args.output_dir, speaker_key.lower())
        os.makedirs(speaker_dir, exist_ok=True)
        
        print(f"\n--- Generating for Speaker: {speaker_name} ---")
        
        for cue, text in to_generate:
            output_path = os.path.join(speaker_dir, f"{cue}.m4a")
            temp_wav = os.path.join(speaker_dir, f"{cue}_temp.wav")
            
            if os.path.exists(output_path) and not args.force:
                print(f"Skipping existing: {output_path}")
                continue

            print(f"Generating '{cue}': {text}")
            
            # 1. Generate temp WAV
            cmd_gen = [
                "uv", "run", "voice_prompt_generator/worker.py",
                "--speaker", speaker_name,
                "--text", text,
                "--output", temp_wav
            ]
            
            try:
                subprocess.run(cmd_gen, check=True, capture_output=True)
                
                # 2. Convert to M4A (AAC) using afconvert (macOS native)
                # -f m4af = M4A file format, -d aac = AAC data format
                cmd_conv = ["afconvert", "-f", "m4af", "-d", "aac", temp_wav, output_path]
                subprocess.run(cmd_conv, check=True)
                
                # 3. Clean up temp file
                if os.path.exists(temp_wav):
                    os.remove(temp_wav)
                    
                print(f"Saved compressed M4A to {output_path}")
            except subprocess.CalledProcessError as e:
                print(f"Failed to generate {cue} for {speaker_name}: {e.stderr.decode() if e.stderr else str(e)}")
            except Exception as e:
                print(f"Error during conversion: {e}")

if __name__ == "__main__":
    main()
