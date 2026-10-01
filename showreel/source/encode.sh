set -e
cd "$(dirname "$0")"
ffmpeg -loglevel error -y -framerate 60 -i frames/f%04d.png -i sound.wav \
  -c:v libx264 -preset slow -crf 16 -pix_fmt yuv420p -profile:v high -level 4.2 \
  -af "loudnorm=I=-14:TP=-1.5:LRA=11" -c:a aac -b:a 192k -ar 48000 \
  -t 15 -movflags +faststart -metadata title="Destiny Life — Showreel" DestinyLife_Showreel_9x16.mp4
ffmpeg -loglevel error -y -i frames/f0899.png -vf scale=1080:1920 cover.png
ffprobe -v error -show_entries format=duration,size:stream=codec_name,width,height,r_frame_rate -of compact DestinyLife_Showreel_9x16.mp4
