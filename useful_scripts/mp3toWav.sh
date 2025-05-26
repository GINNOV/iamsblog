#!/bin/bash

# Check if input parameter is provided
if [ -z "$1" ]; then
  echo "Usage: $0 inputfile.mp3"
  exit 1
fi

# Input and output files
input_file="$1"
output_file="${input_file%.*}.wav"

# Convert MP3 to WAV using ffmpeg
/opt/homebrew/bin/ffmpeg -i "$input_file" "$output_file"

# Check if conversion was successful
if [ $? -eq 0 ]; then
  echo "Conversion successful: $output_file"
else
  echo "Conversion failed"
fi

# Check if extraction was successful
if [[ $? -eq 0 && -f "$output_file" ]]; then
    message="Success!\nSource: $input_file\nFrame: \nOutput: $output_file"
    show_notification "$message" "File converted"
    echo "$output_file"
else
    error_message="Failed to convert audio file from $input_file"
    show_notification "$error_message" "Error: Audio Extraction"
    echo "$error_message" >&2
    exit 1
fi