#!/bin/bash
# Check if input parameter is provided
if [ -z "$1" ]; then
  echo "Usage: $0 inputfile.wav"
  exit 1
fi

# Input and output files
input_file="$1"
output_file="${input_file%.*}.mp4"

# Convert WAV to MP4 (audio only) using ffmpeg
/opt/homebrew/bin/ffmpeg -i "$input_file" -vn -acodec aac "$output_file"
conversion_status=$?

# Check if conversion was successful
if [ $conversion_status -eq 0 ] && [ -f "$output_file" ]; then
  message="Success!\nSource: $input_file\nOutput: $output_file"
  
  say "file converted. It's in the podcast folder in downloads."
  echo "$output_file"
else
  error_message="Failed to convert audio file from $input_file"
  
  say "convertion failed, check the logs."
  echo "$error_message" >&2
  exit 1
fi