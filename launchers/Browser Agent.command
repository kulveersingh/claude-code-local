#!/bin/bash
# Browser Agent — controls Brave with local AI
# Double-click to launch

CLAUDE_BIN="$HOME/.local/bin/claude"
BROWSER_PROMPT_FILE="$HOME/.claude/browser-agent-prompt.txt"
BROWSER_MCP="$HOME/.claude/browser-use-mcp.json"
PROXY="$HOME/.local/claude-local-proxy/proxy.py"

# Ensure Ollama is running
if ! pgrep -x "ollama" >/dev/null 2>&1; then
  ollama serve >/dev/null 2>&1 &
  sleep 3
fi

# Start local proxy if not running
if ! lsof -i :4000 >/dev/null 2>&1; then
  python3 "$PROXY" >/dev/null 2>&1 &
  sleep 2
fi

clear
echo ""
echo "  → Browser Agent (local: qwen3.5:4b via haiku)"
echo "  → Controls Brave browser with AI"
echo ""

PROMPT=$(cat "$BROWSER_PROMPT_FILE")
ANTHROPIC_BASE_URL=http://localhost:4000 \
ANTHROPIC_API_KEY=sk-local \
exec "$CLAUDE_BIN" --model claude-haiku-4-5-20251001 \
  --dangerously-skip-permissions \
  --mcp-config "$BROWSER_MCP" \
  --append-system-prompt "$PROMPT"
