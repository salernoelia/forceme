import json
import os
import argparse
import subprocess
import shutil

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
        "ryan": "ryan",
        "aiden": "aiden",
        "onoAnna": "ono_anna",
        "sohee": "sohee",
        "eric": "eric",
        "dylan": "dylan",
        "serena": "serena",
        "vivian": "vivian",
        "uncleFu": "uncle_fu"
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
        elif isinstance(value, str):
             # Handle simple string prompts like extension_added
             to_generate.append((key, value))

    speakers = [args.speaker] if args.speaker else VOICES.keys()

    for speaker_key in speakers:
        speaker_name = VOICES.get(speaker_key)
        if not speaker_name:
            print(f"Warning: Unknown speaker key '{speaker_key}'. Skipping.")
            continue
            
        # Create a speaker-specific subdirectory to keep things organized
        speaker_dir = os.path.join(args.output_dir, speaker_key.lower())
        os.makedirs(speaker_dir, exist_ok=True)
        
        print(f"\n--- Generating for Speaker: {speaker_name} ---")
        
        for cue, text in to_generate:
            filename = f"{speaker_key.lower()}_{cue}.m4a"
            output_path = os.path.join(speaker_dir, filename)
            temp_wav = os.path.join(speaker_dir, f"{speaker_key.lower()}_{cue}_temp.wav")
            
            if os.path.exists(output_path) and not args.force:
                print(f"Skipping existing: {output_path}")
                continue

            print(f"Generating '{cue}': {text}")
            
            # 1. Generate temp WAV
            uv_path = "uv"
            local_uv = os.path.expanduser("~/.local/bin/uv")
            if not shutil.which("uv") and os.path.exists(local_uv):
                uv_path = local_uv

            cmd_gen = [
                uv_path, "run", "voice_prompt_generator/worker.py",
                "--speaker", speaker_name,
                "--text", text,
                "--output", temp_wav
            ]
            
            try:
                subprocess.run(cmd_gen, check=True, capture_output=True)
                
                # 2. Convert to M4A (AAC) using afconvert (macOS native)
                cmd_conv = ["afconvert", "-f", "m4af", "-d", "aac", temp_wav, output_path]
                subprocess.run(cmd_conv, check=True)
                
                # 3. Clean up temp file
                if os.path.exists(temp_wav):
                    os.remove(temp_wav)
                    
                print(f"Saved compressed M4A to {output_path}")
            except subprocess.CalledProcessError as e:
                stderr = e.stderr.decode() if e.stderr else str(e)
                print(f"Failed to generate {cue} for {speaker_name}: {stderr}")
            except Exception as e:
                print(f"Error during conversion: {e}")

if __name__ == "__main__":
    main()
