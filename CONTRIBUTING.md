# Contributing

Contributions are welcome through GitHub issues and pull requests.

1. Fork the repository and create a focused branch.
2. Keep downloaded model weights and runtime binaries out of commits. The
   documented demo model is the only tracked weight file.
3. Run `pwsh tests/Test-Generators.ps1` and `bash tests/test-generators.sh` when
   those shells are available.
4. Explain the platforms tested and any user-visible behavior changes in the
   pull request.

Please keep the launchers dependency-light and preserve the localhost-only
security default.
