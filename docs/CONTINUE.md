# Use LLM Anywhere with Continue

LLM Anywhere exposes local GGUF models through a local API. The launchers
also generate a Continue YAML configuration containing one entry per model.

## 1. Start the server

On Windows, run:

```bat
Start-Windows.bat
```

On macOS or Ubuntu, run:

```bash
bash Start-Mac-or-Ubuntu.sh
```

Keep the terminal open. By default, the server runs at
`http://127.0.0.1:8080` and writes `continue-config.yaml` in the project root.

## 2. Install Continue

Install the **Continue** extension from the VS Code marketplace. Open Continue's
configuration and locate the YAML config. Its conventional path is:

- Windows: `%USERPROFILE%\.continue\config.yaml`
- macOS/Linux: `~/.continue/config.yaml`

Back up an existing configuration before replacing or merging it.

## 3. Add the generated model entries

Either copy the complete generated `continue-config.yaml`, or merge its entries
into the `models:` list of an existing configuration. Reload the VS Code window
after saving.

The generated entries use the `chat`, `edit`, and `apply` roles. Autocomplete
and embeddings are intentionally omitted because they work best with models
designed for those tasks.

## 4. Confirm connectivity

With the server running, open:

```text
http://127.0.0.1:8080/v1/models
```

If `PORTABLELLM_PORT` was changed, use that port instead. A JSON response listing
your model IDs confirms the API is reachable.

## Troubleshooting

- **Connection refused:** Start the launcher and confirm the port in Continue
  matches the server port.
- **Model is missing:** Restart the launcher after changing `models/`, merge the
  regenerated config, and reload VS Code.
- **Model fails to load:** Use a smaller model or quantization, shorten the
  context, or set `PORTABLELLM_BACKEND=cpu` if the GPU backend is the problem.
- **First response is slow:** A model must be loaded from disk after startup or
  after switching models.
- **Agent mode is unreliable:** Small local models can be good at focused chat
  and edits but may not reliably perform complex tool calls.

The local server is unauthenticated. Keep it bound to `127.0.0.1`.
