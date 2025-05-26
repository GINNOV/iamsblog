🎞️ Extract Video Frame Script

This Zsh script allows you to extract a specific frame from a video file using FFmpeg on macOS. Notifications are displayed via the macOS Notification Center using AppleScript. I use this with a shortcut.

📋 Requirements
	•	macOS
	•	FFmpeg installed at /opt/homebrew/bin/ffmpeg
	•	Zsh (#!/bin/zsh)
	•	AppleScript (built into macOS)

🔧 Installation
	1.	Ensure FFmpeg is installed via Homebrew:

brew install ffmpeg


	2.	Save the script to a file, e.g., extract_frame.sh.
	3.	Make it executable:

chmod +x extract_frame.sh



▶️ Usage

./extract_frame.sh <video_file> <frame_number>

Arguments:
	•	<video_file>: Path to the video file (e.g., movie.mp4)
	•	<frame_number>: The specific frame number you want to extract

Example:

./extract_frame.sh sample.mp4 150

This will extract the 150th frame from sample.mp4 and save it as sample_frame_150.png in the same directory.

🔔 Notifications

The script uses macOS notifications to report:
	•	Usage errors
	•	File or FFmpeg availability issues
	•	Success/failure of frame extraction

🛠️ Script Features
	•	Verifies that the correct number of arguments are provided
	•	Checks for the existence of the input file
	•	Verifies that FFmpeg is installed at the specified path
	•	Notifies user of success or failure via Notification Center

📂 Output

The extracted frame is saved as a .png file in the format:

<original_filename>_frame_<frame_number>.png

🧼 Cleanup / Customization

You can modify the script to:
	•	Change the FFmpeg path if installed elsewhere
	•	Use different output formats (e.g., .jpg)
	•	Customize the notification style or content