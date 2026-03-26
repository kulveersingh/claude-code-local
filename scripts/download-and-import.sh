#!/bin/bash
# Auto-resuming download + Ollama import for Qwen 3.5 122B
# Run with: bash ~/qwen3.5-122b/download-and-import.sh
cd "$HOME/qwen3.5-122b"

BASE="https://huggingface.co/unsloth/Qwen3.5-122B-A10B-GGUF/resolve/main/Q4_K_M"

download_with_retry() {
  local file="$1"
  local url="$2"
  local expected_min_gb="$3"
  while true; do
    curl -L -C - --retry 10 --retry-delay 5 --retry-max-time 600 -o "$file" "$url"
    # Check if file is at least expected size
    local size_bytes=$(stat -f%z "$file" 2>/dev/null || echo 0)
    local size_gb=$((size_bytes / 1073741824))
    if [ "$size_gb" -ge "$expected_min_gb" ]; then
      echo "DONE: $file ($size_gb GB)"
      break
    fi
    echo "Download incomplete ($size_gb GB), retrying in 10s..."
    sleep 10
  done
}

echo "=== Downloading Qwen 3.5 122B Q4_K_M ==="
echo "Files resume automatically if interrupted."
echo ""

# Part 1 (metadata, ~10MB) - already done
if [ ! -f "Qwen3.5-122B-A10B-Q4_K_M-00001-of-00003.gguf" ]; then
  download_with_retry "Qwen3.5-122B-A10B-Q4_K_M-00001-of-00003.gguf" "$BASE/Qwen3.5-122B-A10B-Q4_K_M-00001-of-00003.gguf" 0
fi

# Part 2 (46.5GB) and Part 3 (24.7GB) in parallel
download_with_retry "Qwen3.5-122B-A10B-Q4_K_M-00002-of-00003.gguf" "$BASE/Qwen3.5-122B-A10B-Q4_K_M-00002-of-00003.gguf" 43 &
download_with_retry "Qwen3.5-122B-A10B-Q4_K_M-00003-of-00003.gguf" "$BASE/Qwen3.5-122B-A10B-Q4_K_M-00003-of-00003.gguf" 23 &
wait

echo ""
echo "=== All parts downloaded! Importing into Ollama... ==="

cat > Modelfile <<'EOF'
FROM ./Qwen3.5-122B-A10B-Q4_K_M-00001-of-00003.gguf
EOF

ollama create qwen3.5:122b -f Modelfile

echo ""
echo "=== DONE! Run with: ollama run qwen3.5:122b ==="
