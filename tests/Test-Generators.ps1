$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("portable-ai-models-test-" + [guid]::NewGuid())
$models = Join-Path $tempRoot "models"
$output = Join-Path $tempRoot "continue-config.yaml"

try {
    New-Item -ItemType Directory -Force -Path $models | Out-Null
    New-Item -ItemType File -Path (Join-Path $models "alpha.gguf") | Out-Null
    New-Item -ItemType File -Path (Join-Path $models "model beta.GGUF") | Out-Null

    & (Join-Path $root "Generate-Continue-Config.ps1") `
        -ModelsDir $models -OutputPath $output -ServerPort 9090

    $config = Get-Content -LiteralPath $output -Raw
    $checks = @(
        "name: Portable AI Models",
        "provider: llama.cpp",
        "model: `"alpha`"",
        'model: "model beta"',
        'apiBase: "http://127.0.0.1:9090"'
    )
    foreach ($check in $checks) {
        if (-not $config.Contains($check)) {
            throw "Generated configuration is missing: $check"
        }
    }

    $failedAsExpected = $false
    try {
        & (Join-Path $root "Generate-Continue-Config.ps1") `
            -ModelsDir $models -OutputPath $output -ServerPort 70000
    } catch {
        $failedAsExpected = $true
    }
    if (-not $failedAsExpected) {
        throw "Invalid port test did not fail."
    }

    Write-Host "PowerShell generator tests passed."
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
