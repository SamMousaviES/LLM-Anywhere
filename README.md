# LLM Anywhere

[![CI](https://github.com/SamMousaviES/LLM-Anywhere/actions/workflows/ci.yml/badge.svg)](https://github.com/SamMousaviES/LLM-Anywhere/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![llama.cpp](https://img.shields.io/badge/runtime-llama.cpp-orange)](https://github.com/ggml-org/llama.cpp)

Your models. Your machine. Anywhere.

LLM Anywhere is a lightweight toolkit for running GGUF language models locally
on Windows, macOS, and Ubuntu. Powered by
[`llama.cpp`](https://github.com/ggml-org/llama.cpp), it provides hardware
acceleration, a browser interface, an OpenAI-compatible API, and Continue
integration for private AI-assisted development. A tiny demo model is bundled;
you can add models that better fit your hardware and task.

The launchers:

- select a native runtime for the current operating system;
- use Vulkan or Metal acceleration when available and fall back to CPU;
- discover every `.gguf` file in `models/`;
- expose the service only on `127.0.0.1` by default; and
- generate a [Continue](https://www.continue.dev/) configuration for VS Code.

The repository includes one 92 MB demo model. Larger model weights and runtime
binaries are excluded so you can choose what to download.

## Quick start

### Windows 10/11 (x64)

```powershell
git clone https://github.com/SamMousaviES/LLM-Anywhere.git
cd LLM-Anywhere
powershell -ExecutionPolicy Bypass -File .\Setup-Windows.ps1
```

Then run the included demo model:

```powershell
.\Start-Windows.bat
```

### macOS or Ubuntu

```bash
git clone https://github.com/SamMousaviES/LLM-Anywhere.git
cd LLM-Anywhere
bash Setup-Mac-or-Ubuntu.sh
```

Then run the included demo model:

```bash
bash Start-Mac-or-Ubuntu.sh
```

Open <http://127.0.0.1:8080> for the built-in interface. The API is available
at `http://127.0.0.1:8080/v1`. Select
`SmolLM2-135M-Instruct.Q4_0` in the model picker.

## Download a model

The [bundled SmolLM2 model](models/README.md) is for a quick functional demo.
Its 135 million parameters limit its reasoning and coding quality. For better
results, add a larger GGUF instruct model. For example, after installing
the [Hugging Face CLI](https://huggingface.co/docs/huggingface_hub/guides/cli):

```bash
# Lightweight upgrade from the bundled demo
hf download ggml-org/Qwen3.5-0.8B-GGUF Qwen3.5-0.8B-Q4_0.gguf --local-dir models

# More capable 4B model (requires more memory)
hf download ggml-org/gemma-3-4b-it-GGUF gemma-3-4b-it-Q4_K_M.gguf --local-dir models
```

You can also download a `.gguf` file in a browser and place it directly in the
`models` directory. Always read the model card and comply with the model's own
license and usage terms.

See [Choosing and downloading models](docs/MODELS.md) for sizing, quantization,
download options, and model-safety guidance.

## Configuration

The launchers support these environment variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `PORTABLELLM_PORT` | `8080` | Local HTTP port |
| `PORTABLELLM_CONTEXT_SIZE` | `8192` on Windows; `4096` on macOS/Linux | Maximum context tokens |
| `PORTABLELLM_BACKEND` | `auto` | `auto` or `cpu`; use `cpu` to disable GPU probing |

Example:

```bash
PORTABLELLM_PORT=9090 PORTABLELLM_CONTEXT_SIZE=8192 bash Start-Mac-or-Ubuntu.sh
```

Windows Command Prompt equivalent:

```bat
set PORTABLELLM_PORT=9090
set PORTABLELLM_CONTEXT_SIZE=8192
Start-Windows.bat
```

With `auto`, the GPU builds use `llama.cpp` memory fitting to choose how much
of a model to put on the GPU. Remaining layers run from system RAM on the CPU.
On Windows, the KV cache also stays in RAM. Apple Silicon uses shared memory
for its CPU and GPU, so it has no separate VRAM pool to overflow into RAM.
The specified context size stays fixed; a model still needs enough total RAM
and may fail if even partial offload does not fit. Set `PORTABLELLM_BACKEND=cpu`
to run entirely on the CPU, or reduce the context size for a large model.

Only one model is kept in memory at a time. Switching models can therefore make
the first request slower while the new weights load.

## Continue for VS Code

Each launch regenerates `continue-config.yaml` from the models currently in the
`models/` directory. Follow [the Continue setup guide](docs/CONTINUE.md) to add
those entries to VS Code.

## Supported platforms

| Platform | Acceleration | CPU fallback |
| --- | --- | --- |
| Windows x64 | Vulkan | Yes |
| macOS Apple Silicon | Metal | Yes |
| macOS Intel | Metal/CPU | Yes |
| Ubuntu x64 | Vulkan | Yes |
| Ubuntu ARM64 | CPU | Already CPU based |

The setup scripts obtain official prebuilt `llama.cpp` artifacts. Other Linux
distributions may work but are not currently covered by the launchers.

## Security and privacy

Prompts and model inference stay on the local machine. The server has no API
authentication, so the launchers deliberately bind to loopback only. Do not
change the host to `0.0.0.0` or expose the port to the internet without adding
authentication and appropriate network controls. See [SECURITY.md](SECURITY.md).

## Project layout

```text
.
|-- models/                       # Bundled demo; your added GGUF files are ignored
|-- docs/
|   |-- CONTINUE.md               # Continue/VS Code integration
|   `-- MODELS.md                 # Model selection and downloads
|-- Generate-Continue-Config.*    # Generated model entries
|-- Setup-*                       # Download the native llama.cpp runtime
`-- Start-*                       # Start the local server
```

## License

The launcher and configuration code in this repository is available under the
[MIT License](LICENSE). The bundled model is under
[Apache 2.0](models/LICENSE-APACHE-2.0.txt). `llama.cpp` and other downloaded
models are separate works with their own licenses.
