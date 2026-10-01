#!/usr/bin/env bash
# Usage : encode.sh <dossier_images> <son.wav> <sortie.mp4> [ext=jpg] [fps=60]
set -euo pipefail
FR="$1"; WAV="$2"; OUT="$3"; EXT="${4:-jpg}"; FPS="${5:-60}"
DUR=$(python3 -c "import wave;w=wave.open('$WAV');print(w.getnframes()/w.getframerate())")
ffmpeg -loglevel error -y -framerate "$FPS" -i "$FR/f%04d.$EXT" -i "$WAV" \
  -c:v libx264 -preset slow -crf 16 -pix_fmt yuv420p -profile:v high -level 4.2 \
  -af "loudnorm=I=-14:TP=-1.5:LRA=11" -c:a aac -b:a 192k -ar 48000 \
  -t "$DUR" -movflags +faststart "$OUT"
ffprobe -v error -show_entries format=duration,size:stream=codec_name,width,height,r_frame_rate -of compact "$OUT"
