# InstaFlow Pro v2.6 dependency bootstrapper
# Downloads missing runtime tools into .\tools without requiring winget or administrator rights.
[CmdletBinding()]
param(
    [switch]$ForceUpdate
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$root = $PSScriptRoot
$tools = Join-Path $root 'tools'
$tempRoot = Join-Path $env:TEMP ('InstaFlowTools-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tools | Out-Null
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

function Write-Step([string]$message) {
    Write-Host ('[InstaFlow] ' + $message) -ForegroundColor Cyan
}

function Download-File([string]$url, [string]$destination, [int64]$minimumBytes = 1024) {
    $partial = $destination + '.download'
    Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue
    try {
        Invoke-WebRequest -Uri $url -OutFile $partial -UseBasicParsing -TimeoutSec 900 -MaximumRedirection 10 -Headers @{ 'User-Agent'='InstaFlow-Pro/2.6' }
    } catch {
        Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue
        $curl = Get-Command 'curl.exe' -ErrorAction SilentlyContinue
        if (-not $curl) { throw }
        & $curl.Source -L --fail --silent --show-error --connect-timeout 20 --max-time 900 -A 'InstaFlow-Pro/2.6' -o $partial -- $url
        if ($LASTEXITCODE -ne 0) { throw ('Download failed: ' + $url) }
    }
    if (-not (Test-Path -LiteralPath $partial)) { throw ('Download produced no file: ' + $url) }
    $size = (Get-Item -LiteralPath $partial).Length
    if ($size -lt $minimumBytes) {
        Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue
        throw ('Downloaded file is unexpectedly small: ' + $url)
    }
    Move-Item -LiteralPath $partial -Destination $destination -Force
}

function Get-GitHubLatestAsset([string]$repository, [string]$assetRegex) {
    $api = 'https://api.github.com/repos/' + $repository + '/releases/latest'
    $release = Invoke-RestMethod -Uri $api -UseBasicParsing -TimeoutSec 60 -Headers @{ 'User-Agent'='InstaFlow-Pro/2.6'; 'Accept'='application/vnd.github+json' }
    $asset = @($release.assets | Where-Object { [string]$_.name -match $assetRegex } | Select-Object -First 1)
    if (-not $asset) { throw ('No matching release asset found for ' + $repository) }
    return [string]$asset.browser_download_url
}

function Install-YtDlp {
    $dest = Join-Path $tools 'yt-dlp.exe'
    if ((Test-Path -LiteralPath $dest) -and -not $ForceUpdate) { return }
    Write-Step 'Downloading yt-dlp...'
    Download-File 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe' $dest 5000000
}

function Install-Deno {
    $dest = Join-Path $tools 'deno.exe'
    if ((Test-Path -LiteralPath $dest) -and -not $ForceUpdate) { return }
    Write-Step 'Downloading Deno JavaScript runtime...'
    $zip = Join-Path $tempRoot 'deno.zip'
    $extract = Join-Path $tempRoot 'deno'
    Download-File 'https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip' $zip 5000000
    New-Item -ItemType Directory -Force -Path $extract | Out-Null
    Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force
    $exe = Get-ChildItem -LiteralPath $extract -Recurse -Filter 'deno.exe' -File | Select-Object -First 1
    if (-not $exe) { throw 'deno.exe was not found in the downloaded archive.' }
    Copy-Item -LiteralPath $exe.FullName -Destination $dest -Force
}

function Install-FFmpeg {
    $ffmpeg = Join-Path $tools 'ffmpeg.exe'
    $ffprobe = Join-Path $tools 'ffprobe.exe'
    if ((Test-Path -LiteralPath $ffmpeg) -and (Test-Path -LiteralPath $ffprobe) -and -not $ForceUpdate) { return }
    Write-Step 'Downloading FFmpeg (this is the largest dependency)...'
    $zip = Join-Path $tempRoot 'ffmpeg.zip'
    $extract = Join-Path $tempRoot 'ffmpeg'
    Download-File 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' $zip 50000000
    New-Item -ItemType Directory -Force -Path $extract | Out-Null
    Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force
    $ff = Get-ChildItem -LiteralPath $extract -Recurse -Filter 'ffmpeg.exe' -File | Select-Object -First 1
    $fp = Get-ChildItem -LiteralPath $extract -Recurse -Filter 'ffprobe.exe' -File | Select-Object -First 1
    if (-not $ff -or -not $fp) { throw 'FFmpeg executables were not found in the downloaded archive.' }
    Copy-Item -LiteralPath $ff.FullName -Destination $ffmpeg -Force
    Copy-Item -LiteralPath $fp.FullName -Destination $ffprobe -Force
}

function Install-Aria2 {
    $dest = Join-Path $tools 'aria2c.exe'
    if ((Test-Path -LiteralPath $dest) -and -not $ForceUpdate) { return }
    Write-Step 'Downloading aria2 accelerator...'
    $zip = Join-Path $tempRoot 'aria2.zip'
    $extract = Join-Path $tempRoot 'aria2'
    $url = Get-GitHubLatestAsset 'aria2/aria2' 'win-64bit.*\.zip$'
    Download-File $url $zip 500000
    New-Item -ItemType Directory -Force -Path $extract | Out-Null
    Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force
    $exe = Get-ChildItem -LiteralPath $extract -Recurse -Filter 'aria2c.exe' -File | Select-Object -First 1
    if (-not $exe) { throw 'aria2c.exe was not found in the downloaded archive.' }
    Copy-Item -LiteralPath $exe.FullName -Destination $dest -Force
}

function Install-GalleryDl {
    $dest = Join-Path $tools 'gallery-dl.exe'
    if ((Test-Path -LiteralPath $dest) -and -not $ForceUpdate) { return }
    Write-Step 'Downloading gallery-dl...'
    $downloaded = $false
    $errors = New-Object System.Collections.ArrayList
    $sources = New-Object System.Collections.ArrayList
    try {
        $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/mikf/gallery-dl/releases/latest' -UseBasicParsing -TimeoutSec 60 -Headers @{ 'User-Agent'='InstaFlow-Pro/2.6'; 'Accept'='application/vnd.github+json' }
        $tag = [string]$rel.tag_name
        if ($tag) { [void]$sources.Add(('https://codeberg.org/mikf/gallery-dl/releases/download/' + $tag + '/gallery-dl.exe')) }
    } catch { [void]$errors.Add($_.Exception.Message) }
    [void]$sources.Add('https://github.com/mikf/gallery-dl/releases/latest/download/gallery-dl.exe')
    [void]$sources.Add('https://codeberg.org/mikf/gallery-dl/releases/download/v1.32.15/gallery-dl.exe')
    foreach ($url in $sources) {
        try {
            Download-File ([string]$url) $dest 400000
            $downloaded = $true
            break
        } catch { [void]$errors.Add($_.Exception.Message) }
    }
    if (-not $downloaded) { throw ('gallery-dl could not be downloaded. ' + ($errors -join ' | ')) }
}

$requiredFailures = New-Object System.Collections.ArrayList
$optionalFailures = New-Object System.Collections.ArrayList
try { Install-YtDlp } catch { [void]$requiredFailures.Add('yt-dlp: ' + $_.Exception.Message) }
try { Install-Deno } catch { [void]$requiredFailures.Add('Deno: ' + $_.Exception.Message) }
try { Install-FFmpeg } catch { [void]$requiredFailures.Add('FFmpeg: ' + $_.Exception.Message) }
try { Install-GalleryDl } catch { [void]$optionalFailures.Add('gallery-dl: ' + $_.Exception.Message) }
try { Install-Aria2 } catch { [void]$optionalFailures.Add('aria2: ' + $_.Exception.Message) }

try {
    $env:Path = $tools + ';' + [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
} catch { $env:Path = $tools + ';' + $env:Path }

if ($optionalFailures.Count -gt 0) {
    foreach ($warning in $optionalFailures) { Write-Host ('[InstaFlow] Optional tool warning: ' + $warning) -ForegroundColor Yellow }
}
if ($requiredFailures.Count -gt 0) {
    foreach ($failure in $requiredFailures) { Write-Host ('[InstaFlow] Required tool error: ' + $failure) -ForegroundColor Red }
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Host '[InstaFlow] Runtime tools are ready.' -ForegroundColor Green
Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
exit 0
