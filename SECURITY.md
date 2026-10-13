# Security policy

## Reporting a vulnerability

Please report security issues privately through GitHub's **Security** tab using
a private vulnerability report. Do not include private prompts, model files,
API keys, or other sensitive data in a public issue.

## Local server boundary

LLM Anywhere starts an unauthenticated local inference server. The
provided launchers bind it to `127.0.0.1`, which limits access to applications
on the same computer. Exposing the server on a LAN or the public internet is
outside this project's secure default and requires authentication, TLS, and
network access controls.

Downloaded runtimes and models are third-party artifacts. Obtain them from
trusted sources, review their licenses, and retain any published checksums or
signatures when possible.
