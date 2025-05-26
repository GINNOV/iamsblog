📁 organize_files.sh

A Zsh script to organize files in a directory into alphabetically-named folders (A–Z) and a special non_alphabetic folder for files that don’t start with a letter.

Supports preview mode, parallel execution, and custom source directories.

⸻

🚀 Features
	•	Preview how files would be organized without making changes.
	•	Actually organize files using rsync (optionally in parallel).
	•	Supports alphabetical and non-alphabetic sorting.
	•	Parallel processing via GNU Parallel.

⸻

🧾 Usage

./organize_files.sh [--organize] [--root /path/to/directory] [--parallel N]

Options

Option	Description
--organize	Actually perform the file organization (default is preview mode).
--root DIR	Target directory for organizing files. Default is /Volumes/ME/Amiga/BS1/.
--parallel N	Use N parallel jobs (requires parallel installed).
--help	Show help message and exit.


⸻

🔍 Examples

Preview (default)

./organize_files.sh --root /path/to/my/files

Organize files in-place

./organize_files.sh --organize --root /path/to/my/files

Organize with 4 parallel jobs

./organize_files.sh --organize --root /path/to/my/files --parallel 4


⸻

🧰 Requirements
	•	Zsh shell
	•	rsync (for organizing mode)
	•	parallel (for --parallel N, install via brew install parallel on macOS)

⸻

📂 How It Works
	•	Files starting with A–Z are moved into folders named A/, B/, etc.
	•	Files not starting with a letter go into non_alphabetic/.
	•	Uses rsync --remove-source-files to move files cleanly.

⸻

🛑 Safeguards
	•	Files are not modified unless --organize is specified.
	•	Preview mode shows a visual tree of how files would be grouped.
	•	Errors and warnings are reported clearly.

⸻

🧪 Sample Output (Preview)

Preview of file organization for: /path/to/files
files/
├── A/
│   ├── Apple.txt
│   └── Atlas.jpg
├── B/
│   └── Banana.pdf
└── non_alphabetic/
    └── _notes.txt


⸻

📝 License

MIT — free to use and modify.