# Benchmarks — Claude Code Local (MLX Native Server)

## System

| | |
|---|---|
| **Machine** | MacBook Pro M5 Max |
| **Chip** | Apple M5 Max |
| **Memory** | 128 GB Unified |
| **Model** | Qwen 3.5 122B-A10B (4-bit MLX) |
| **Model size on disk** | 65 GB |
| **Architecture** | MoE — 122B total, 10B active per token |
| **Server** | MLX Native Anthropic Server (custom, ~200 lines Python) |
| **KV cache** | 4-bit quantized (MLX Metal GPU) |
| **Claude Code** | v2.1.84 |
| **Date** | March 26, 2026 |

## Generation Speed

| Max Tokens | Output Tokens | Time | **Tokens/sec** |
|:---:|:---:|:---:|:---:|
| 100 | 100 | 2.2s | **45.0 tok/s** |
| 500 | 500 | 7.7s | **64.8 tok/s** |
| 1000 | 1000 | 15.3s | **65.4 tok/s** |

Sustained generation at 65 tok/s. Short requests are slower (45 tok/s) due to prompt processing overhead amortized over fewer tokens.

## Three Generations — Our Optimization Journey

```
Generation Speed (tok/s):

  Gen 1: Ollama + proxy              ████████████████████████████████ 30
  Gen 2: llama.cpp TurboQuant        █████████████████████████████████████████ 41
  Gen 3: MLX Native (no proxy)       █████████████████████████████████████████████████████████████████ 65
```

```
Claude Code Task Time (seconds):

  Gen 1: Ollama + proxy              █████████████████████████████████████████████████████████ 133s
  Gen 2: llama.cpp TurboQuant        █████████████████████████████████████████████████████████ 133s
  Gen 3: MLX Native (no proxy)       ████████ 17.6s
```

| Generation | Stack | tok/s | Claude Code E2E | What Changed |
|:---:|---|:---:|:---:|---|
| 1 | Ollama → Proxy → Claude Code | 30 | 133s | Baseline |
| 2 | llama.cpp TurboQuant → Proxy → Claude Code | 41 | 133s | +37% speed, 4.9x KV compression |
| **3** | **MLX Server → Claude Code (direct)** | **65** | **17.6s** | **+117% speed, eliminated proxy** |

## vs Cloud APIs

| | **MLX Native (Local)** | Claude Sonnet (Cloud) | Claude Opus (Cloud) |
|---|:---:|:---:|:---:|
| **Generation speed** | 65 tok/s | ~80 tok/s | ~40 tok/s |
| **Claude Code task** | 17.6s | ~10s | ~15s |
| **Cost / million tokens** | **$0** | $3 / $15 | $15 / $75 |
| **Privacy** | **100% on-device** | Cloud | Cloud |
| **Works offline** | **Yes** | No | No |
| **Monthly cost** | **$0** | $20-100+ | $20-100+ |

Our local setup **beats cloud Opus on speed** (65 vs 40 tok/s) and is within striking distance of Sonnet.

## Why MLX Native is Faster

| Factor | Impact |
|--------|--------|
| **No proxy** | Eliminated API translation overhead — the #1 bottleneck |
| **MLX framework** | Apple's own ML framework, built for Metal GPU + unified memory |
| **Native Anthropic API** | Server speaks Claude Code's language directly |
| **Unified memory** | Zero-copy between CPU and GPU — model weights stay in place |
| **MoE efficiency** | Only 10B of 122B params activate per token — fast on unified memory |

## Methodology

- All benchmarks run on a warm server (model already loaded)
- Each test run once (not averaged — these are representative single runs)
- Claude Code E2E includes full Claude Code startup, system prompt processing, and generation
- KV cache quantized to 4-bit via MLX's built-in `QuantizedKVCache`
- Temperature: 0.7 (default)
