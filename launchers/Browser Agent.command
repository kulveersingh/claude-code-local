#!/bin/bash
# Brave Browser Agent — Direct MLX + Chrome DevTools Protocol (no Claude Code)
# Double-click to launch

MLX_PYTHON="/Users/dtribe/.local/mlx-server/bin/python3"
MLX_SERVER="/Users/dtribe/.local/mlx-native-server/server.py"
AGENT="/Users/dtribe/.local/browser-agent/agent.py"

# Start 122B MLX server if not running
if ! lsof -i :4000 >/dev/null 2>&1; then
  echo "  Loading Qwen 3.5 122B..."
  "$MLX_PYTHON" "$MLX_SERVER" >/tmp/mlx-server.log 2>&1 &
  while ! curl -s http://localhost:4000/health 2>/dev/null | grep -q "ok"; do sleep 2; done
fi

# Start Brave with remote debugging
if ! lsof -i :9222 >/dev/null 2>&1; then
  # If Brave is running WITHOUT debug port, restart it with the flag
  if pgrep -f "Brave Browser" >/dev/null 2>&1; then
    echo "  Restarting Brave with remote debugging enabled..."
    osascript -e 'quit app "Brave Browser"'
    sleep 2
  else
    echo "  Launching Brave with remote debugging..."
  fi
  open -a "Brave Browser" --args --remote-debugging-port=9222
  # Wait until debug port is actually ready (up to 15s)
  echo -n "  Waiting for Brave debug port"
  for i in $(seq 1 15); do
    if lsof -i :9222 >/dev/null 2>&1; then echo " ready!"; break; fi
    echo -n "."
    sleep 1
  done
  if ! lsof -i :9222 >/dev/null 2>&1; then
    echo ""
    echo "  ERROR: Brave debug port (9222) didn't open. Try closing Brave and running again."
    exit 1
  fi
  # Wait for at least one page/tab to register with CDP
  echo -n "  Waiting for Brave tab"
  for i in $(seq 1 10); do
    if curl -s http://127.0.0.1:9222/json 2>/dev/null | grep -q '"webSocketDebuggerUrl"'; then
      echo " ready!"
      break
    fi
    echo -n "."
    sleep 1
  done
  # If still no tabs, force-create one (Brave requires PUT)
  if ! curl -s http://127.0.0.1:9222/json 2>/dev/null | grep -q '"webSocketDebuggerUrl"'; then
    echo "  Creating new tab..."
    curl -s -X PUT 'http://127.0.0.1:9222/json/new' >/dev/null 2>&1
    sleep 1
  fi
fi

clear
echo ""
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║  Brave Browser Agent                            ║"
echo "  ║  Qwen 3.5 122B · MLX · Brave DevTools         ║"
echo "  ║  iframes + Shadow DOM · no cloud               ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo ""

exec "$MLX_PYTHON" "$AGENT"
