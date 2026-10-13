[CmdletBinding()]
param(
    [ValidateSet("both", "cpu", "vulkan")]
    [string]$Backend = "both"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

if (-not [Environment]::Is64BitOperatingSystem) {
    throw "LLM Anywhere currently requires 64-bit Windows."
}

$root = $PSScriptRoot
$binRoot = Join-Path $root "bin"
$releaseApi = "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest"
$headers = @{ "User-Agent" = "LLM-Anywhere-Setup" }
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("llm-anywhere-" + [guid]::NewGuid())

function Install-LlamaAsset {
    param(
        [Parameter(Mandatory = $true)][object]$Release,
        [Parameter(Mandatory = $true)][string]$AssetName,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $asset = $Release.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
    if (-not $asset) {
        throw "Release asset not found: $AssetName"
    }

    $archive = Join-Path $tempRoot $AssetName
    $extract = Join-Path $tempRoot ([IO.Path]::GetFileNameWithoutExtension($AssetName))
    Write-Host "Downloading $AssetName ..."
    Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $asset.browser_download_url -OutFile $archive
    Expand-Archive -LiteralPath $archive -DestinationPath $extract -Force

    $server = Get-ChildItem -LiteralPath $extract -Recurse -File -Filter "llama-server.exe" |
        Select-Object -First 1
    if (-not $server) {
        throw "The downloaded archive does not contain llama-server.exe: $AssetName"
    }

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Copy-Item -Path (Join-Path $server.Directory.FullName "*") -Destination $Destination -Recurse -Force
    Write-Host "Installed: $Destination"
}

try {
    New-Item -ItemType Directory -Force -Path $tempRoot, $binRoot | Out-Null

    Write-Host "Resolving the current stable llama.cpp build ..."
    $stableRelease = Invoke-RestMethod -Headers $headers -Uri $releaseApi
    $pointer = $stableRelease.assets | Where-Object { $_.name -eq "nightly-tag.txt" } | Select-Object -First 1
    if (-not $pointer) {
        throw "The stable llama.cpp release does not publish nightly-tag.txt."
    }

    $pointerResponse = Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $pointer.browser_download_url
    if ($pointerResponse.Content -is [byte[]]) {
        $buildTag = [Text.Encoding]::UTF8.GetString($pointerResponse.Content).Trim()
    } else {
        $buildTag = ([string]$pointerResponse.Content).Trim()
    }
    if ($buildTag -notmatch '^b[0-9]+$') {
        throw "Unexpected llama.cpp build tag: $buildTag"
    }

    $buildRelease = Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/ggml-org/llama.cpp/releases/tags/$buildTag"

    if ($Backend -in @("both", "cpu")) {
        Install-LlamaAsset -Release $buildRelease `
            -AssetName "llama-$buildTag-bin-win-cpu-x64.zip" `
            -Destination (Join-Path $binRoot "windows-cpu")
    }
    if ($Backend -in @("both", "vulkan")) {
        Install-LlamaAsset -Release $buildRelease `
            -AssetName "llama-$buildTag-bin-win-vulkan-x64.zip" `
            -Destination (Join-Path $binRoot "windows-vulkan")
    }

    New-Item -ItemType Directory -Force -Path (Join-Path $root "models") | Out-Null
    Write-Host ""
    Write-Host "Setup complete (llama.cpp $buildTag)."
    Write-Host "Next: run Start-Windows.bat to try the bundled demo model."
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
