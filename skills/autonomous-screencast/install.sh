#!/usr/bin/env bash
# Universal Installer for the autonomous-screencast skill
# Supports Antigravity, OpenAI Codex, Claude Code, Hermes, and Universal ~/.agents
set -e

SKILL_NAME="autonomous-screencast"
ALIAS_NAME="screencast-tutorial-generator"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo " Installing: $SKILL_NAME"
echo " Source:     $SCRIPT_DIR"
echo "=========================================================="

# 1. Target Directories to check/install
TARGET_DIRS=(
  "$HOME/.agents/skills"
  "$HOME/.codex/skills"
  "$HOME/.gemini/config/skills"
  "$HOME/.claude/skills"
  "$HOME/.hermes/skills"
)

INSTALLED_COUNT=0

for target in "${TARGET_DIRS[@]}"; do
  # Determine parent directory (e.g. ~/.agents, ~/.codex)
  PARENT_DIR="$(dirname "$target")"
  if [ -d "$PARENT_DIR" ] || [ -d "$target" ]; then
    mkdir -p "$target"
    # Remove existing link or directory if updating
    rm -rf "$target/$SKILL_NAME" "$target/$ALIAS_NAME"
    ln -sf "$SCRIPT_DIR" "$target/$SKILL_NAME"
    ln -sf "$SCRIPT_DIR" "$target/$ALIAS_NAME"
    echo " [✓] Installed to: $target/$SKILL_NAME"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
  fi
done

# If run inside a git repo, also link into workspace .agents/skills
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  WORKSPACE_ROOT="$(git rev-parse --show-toplevel)"
  if [ "$WORKSPACE_ROOT" != "$SCRIPT_DIR" ] && [ -d "$WORKSPACE_ROOT" ]; then
    mkdir -p "$WORKSPACE_ROOT/.agents/skills"
    ln -sf "$SCRIPT_DIR" "$WORKSPACE_ROOT/.agents/skills/$SKILL_NAME"
    ln -sf "$SCRIPT_DIR" "$WORKSPACE_ROOT/.agents/skills/$ALIAS_NAME"
    echo " [✓] Linked into workspace: $WORKSPACE_ROOT/.agents/skills/$SKILL_NAME"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
  fi
fi

# Ensure all scripts are executable
chmod +x "$SCRIPT_DIR"/scripts/*.py "$SCRIPT_DIR"/scripts/*.js 2>/dev/null || true

echo "----------------------------------------------------------"
echo " Prerequisite Checks:"

command -v ffmpeg >/dev/null 2>&1 && echo " [✓] ffmpeg: found" || echo " [!] ffmpeg: not found (Install via: brew install ffmpeg / apt install ffmpeg)"
command -v python3 >/dev/null 2>&1 && echo " [✓] python3: found" || echo " [!] python3: not found"
command -v node >/dev/null 2>&1 && echo " [✓] node: found" || echo " [!] node: not found"

if python3 -c "import edge_tts" >/dev/null 2>&1 || command -v edge-tts >/dev/null 2>&1; then
  echo " [✓] edge-tts: found"
else
  echo " [i] edge-tts: not installed. Recommended: pip install edge-tts"
fi

echo "=========================================================="
echo " Installation Complete! ($INSTALLED_COUNT target environments registered)"
echo ""
echo " How to use with your AI Agent:"
echo "   Chat:   'Using the autonomous-screencast skill, record a tutorial for...'"
echo "   CLI:    python3 $SCRIPT_DIR/scripts/run_pipeline.py --video-code DEMO-001 --url https://example.com"
echo "=========================================================="
