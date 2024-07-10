#!/bin/bash

# Loop to generate multiple videos
for i in {1..8}; do
  output_filename="Natalya_20200806_ARM_002-${i}.avi"
  ffmpeg -f lavfi -i nullsrc=s=640x480:d=60 -vf "geq=random(1)*255:128:128" -c:v mpeg4 -t 60 "$output_filename"
done
