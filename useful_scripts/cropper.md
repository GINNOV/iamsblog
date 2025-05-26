# cropper.sh

cropper.sh is a simple Bash script that uses ffmpeg to crop a video file to specified dimensions and offset coordinates.

Features
	•	Crops video to custom width and height
	•	Allows offset specification from top-left corner
	•	Preserves the original audio stream

Requirements
	•	ffmpeg

Usage

`./cropper.sh input.mp4 output.mp4 crop_width crop_height x_offset y_offset`

**Example**

`./cropper.sh input.mp4 output.mp4 640 360 100 50`

This will crop a 640×360 area from input.mp4, starting 100 pixels from the left and 50 pixels from the top, and save the result to output.mp4.

Parameters
	•	input_file – Source video file
	•	output_file – Destination cropped video file
	•	crop_width – Width of the cropped area
	•	crop_height – Height of the cropped area
	•	x_offset – Horizontal offset (in pixels)
	•	y_offset – Vertical offset (in pixels)