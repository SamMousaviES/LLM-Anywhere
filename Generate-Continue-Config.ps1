param(
    [Parameter(Mandatory = $true)][string]$ModelsDir,
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [Parameter(Mandatory = $true)][int]$ServerPort
)

$ErrorActionPreference = "Stop"

if ($ServerPort -lt 1 -or $ServerPort -gt 65535) {
    throw "Invalid port: $ServerPort"
}

$modelFiles = @(Get-ChildItem -LiteralPath $ModelsDir -File |
    Where-Object { $_.Extension -ieq ".gguf" } |
    Sort-Object Name)

if ($modelFiles.Count -eq 0) {
    throw "No GGUF models found in: $ModelsDir"
}

function ConvertTo-YamlQuotedString([string]$Value) {
    return '"' + $Value.Replace('\', '\\').Replace('"', '\"') + '"'
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("name: Portable AI Models")
$lines.Add("version: 1.0.0")
$lines.Add("schema: v1")
$lines.Add("")
$lines.Add("models:")

foreach ($modelFile in $modelFiles) {
    $modelId = [System.IO.Path]::GetFileNameWithoutExtension($modelFile.Name)
    $quotedId = ConvertTo-YamlQuotedString $modelId
    $quotedName = ConvertTo-YamlQuotedString "$modelId (local)"
    $lines.Add("  - name: $quotedName")
    $lines.Add("    provider: llama.cpp")
    $lines.Add("    model: $quotedId")
    $lines.Add("    apiBase: `"http://127.0.0.1:$ServerPort`"")
    $lines.Add("    roles:")
    $lines.Add("      - chat")
    $lines.Add("      - edit")
    $lines.Add("      - apply")
    $lines.Add("")
}

$tempPath = "$OutputPath.tmp"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllLines($tempPath, $lines, $utf8NoBom)
Move-Item -LiteralPath $tempPath -Destination $OutputPath -Force

Write-Host "Generated Continue config: $OutputPath"
Write-Host "Models included: $($modelFiles.Count)"
