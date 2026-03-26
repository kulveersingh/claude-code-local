#!/bin/bash
# MLX LLM Server — OpenAI-compatible API
# Runs on port 8321

MODEL="${1:-mlx-community/Qwen3.5-4B-4bit}"
PORT=8321

echo "Starting MLX server with $MODEL on port $PORT..."
exec "$HOME/.local/mlx-server/bin/mlx_lm.server" \
  --model "$MODEL" \
  --port "$PORT"
