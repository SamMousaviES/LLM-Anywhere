# Choosing and downloading models

LLM Anywhere does not redistribute model weights. You choose the model,
download its GGUF file, and place it in the repository's `models/` directory.
The launchers discover all top-level `.gguf` files when they start.

## What GGUF and quantization mean

[GGUF](https://github.com/ggml-org/ggml/blob/master/docs/gguf.md) is the model
file format consumed by `llama.cpp`. A model repository often offers several
quantizations of the same model. Quantization stores weights with fewer bits,
reducing disk and memory use in exchange for some output quality.

Common choices are:

| Quantization | Relative size | Typical use |
| --- | --- | --- |
| `Q4_K_M` | Small | Best general starting point |
| `Q5_K_M` | Medium | More quality when memory allows |
| `Q6_K` | Larger | High fidelity, slower to load |
| `Q8_0` | Very large | Near-original quality, high memory use |
| `Q4_0` | Small | Broad compatibility; useful when K-quants are unavailable |

Names can vary by publisher. Prefer an instruct/chat variant for conversation
and code assistance; a base model is primarily intended for further training
or specialized completion workflows.

## Estimate the model size

Parameter count and quantization jointly determine file size and memory use.
These are deliberately broad planning ranges for 4-bit models:

| Model class | Approximate model file | Practical expectation |
| --- | --- | --- |
| 0.5B-1.5B | 0.5-1.5 GB | Fast and lightweight; limited reasoning |
| 3B-4B | 2-4 GB | Good portable balance for chat and focused edits |
| 7B-9B | 4-7 GB | Better quality; needs more RAM/VRAM |
| 12B-14B | 7-11 GB | Stronger output; less portable |
| 20B+ | 12 GB and up | Workstation-class memory is often required |

Runtime memory is higher than the file size because the context/KV cache and
working buffers also consume RAM or VRAM. Longer context sizes require more
memory. Start with `Q4_K_M` and a 4096-token context if unsure.

In automatic mode, `llama.cpp` estimates available GPU memory and leaves layers
that do not fit on the GPU in system RAM for CPU processing. This is slower
than fitting the whole model on the GPU. Windows also keeps its KV cache in
RAM by default.
On Apple Silicon, CPU and GPU share the same physical memory. Memory fitting
cannot make a model run if the machine lacks enough total RAM; in that case,
choose a smaller model, a smaller quantization, or a shorter context.

## Download with a browser

1. Open [Hugging Face models](https://huggingface.co/models?library=gguf).
2. Select a trusted model repository and read its model card and license.
3. Open **Files and versions**.
4. Download one `.gguf` quantization, usually `Q4_K_M`.
5. Move the file into this project's `models/` directory.

Some models are gated and require accepting their publisher's terms and signing
in before downloading.

## Download with the Hugging Face CLI

Install the official CLI as described in the
[Hugging Face documentation](https://huggingface.co/docs/huggingface_hub/guides/cli),
then specify both the repository and exact filename:

```bash
# Lightweight starter
hf download ggml-org/Qwen3.5-0.8B-GGUF Qwen3.5-0.8B-Q4_0.gguf --local-dir models

# Balanced general assistant
hf download ggml-org/gemma-3-4b-it-GGUF gemma-3-4b-it-Q4_K_M.gguf --local-dir models
```

The examples are starting points, not endorsements. Model availability and
terms can change. Verify the model card before use.

## Add, remove, or switch models

- Add a model by copying a `.gguf` file into `models/`.
- Remove a model by deleting its file from `models/`.
- Restart the launcher after either change.
- Select among discovered models in the browser or Continue model picker.

The server is started with one-model-at-a-time loading to reduce memory use.
The first request after a switch is therefore slower.

## Licenses and trust

A GGUF conversion does not replace the original model's license. Review both
the GGUF repository and its linked upstream model. Treat model files as
third-party downloads, prefer established publishers, and validate checksums
when the publisher provides them. Do not commit weights to this repository.
