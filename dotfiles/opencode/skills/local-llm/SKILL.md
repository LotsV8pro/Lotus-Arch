---
name: local-llm
description: >
  LLM local: llama-manager, ~/model.ini, binario llama en el puerto 8080,
  modelos gguf, VRAM y n-cpu-moe. Usar al cambiar el modelo local, ajustar
  contexto o diagnosticar OOM en la GPU.
---

# LLM local

## 8. LLM local

- Gestor GUI: `~/.local/bin/llama-manager` (nombre "LLaMA Model Manager").
- Presets: `~/model.ini` · binario `~/.local/bin/llama` · puerto **8080**.
- Modelos locales: `~/models/*.gguf`; descargas HF en `~/.cache/huggingface/hub`.
- Config de opencode: `~/.config/opencode/opencode.json` (provider `local`).
- Config activa: `Qwen3-Coder-30B-A3B` 131k ctx, `n-cpu-moe 42`.
  Medido: prefill ~454 tok/s, generación **42-47 tok/s**, 11,3 GB VRAM.
  **No bajes `n-cpu-moe` de 40 con 131k** → OOM (`cudaMalloc failed`).
- `models-max = 1`: solo un modelo a la vez; si pides dos, el router expulsa uno.
