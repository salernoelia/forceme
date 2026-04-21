A CoreML implementation of the Silero Voice Activity Detection (VAD) model, optimized for Apple platforms (iOS/macOS). This repository contains pre-converted CoreML models ready for use in Swift applications.

See FluidAudio Repo link at the top for more information

Model Description
Developed by: Silero Team (original), converted by FluidAudio

Model type: Voice Activity Detection

License: MIT

Parent Model: silero-vad

This is how the model performs against the silero-vad v6.0.0 basline Pytorch JIT version

graphs/yc_standard_comparison_20250915_205721_2c04b81.png
graphs/yc_256ms_comparison_20250915_205721_2c04b81.png

Note that we tested the quantized versions, as the model is already tiny, theres no performance imporvement at all.

This is how the different models compare in terms of speed, the 256s takes in 8 chunks of 32ms and processes it in batches so its much faster
graphs/yc_performance_20250915_205721_2c04b81.png

Conversion code is available here: FluidInference/mobius

Intended Use
Primary Use Cases
Real-time voice activity detection in iOS/macOS applications
Speech preprocessing for ASR systems
Audio segmentation and filtering
How to Use
Citation

@misc{silero-vad-coreml, title={CoreML Silero VAD}, author={FluidAudio Team}, year={2024},

url={https://huggingface.co/alexwengg/coreml-silero-vad} }

@misc{silero-vad, title={Silero VAD}, author={Silero Team}, year={2021}, url={https://github.com/snakers4/silero-vad} }

GitHub: https://github.com/FluidAudio/FluidAudioSwift

silero-vad-coreml
7.31 MB
⌘ K


3 contributors
bweng's picture
bweng
Update README.md
37b639c
verified
7 months ago
graphs
Upload 3 files
7 months ago
silero-vad-unified-256ms-v6.0.0.mlmodelc
d7997f98bf4209cfb6c2d5bbc4d96d15bd9350ed
7 months ago
silero-vad-unified-256ms-v6.0.0.mlpackage
Upload 16 files
7 months ago
silero-vad-unified-v6.0.0.mlmodelc
d7997f98bf4209cfb6c2d5bbc4d96d15bd9350ed
7 months ago
silero-vad-unified-v6.0.0.mlpackage
Upload 16 files
7 months ago
silero_vad.mlmodelc
Upload 5 files
8 months ago
silero_vad_se_trained.mlpackage
Upload 3 files
8 months ago
silero_vad_se_trained_4bit.mlmodelc
Upload 5 files
7 months ago
.gitattributes
2.56 kB
Upload 3 files
7 months ago
README.md
2.47 kB
Update README.md
7 months ago
config.json
2 Bytes
Create config.json (#1)