# Ensures bundled UI images/icons exist before Flutter build (Windows CI).
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$AssetDir = Join-Path $Root "app\assets\img"
$BaseUrl = if ($env:LOCALSEND_ASSETS_BASE) { $env:LOCALSEND_ASSETS_BASE } else { "https://raw.githubusercontent.com/localsend/localsend/main/app/assets/img" }

New-Item -ItemType Directory -Force -Path $AssetDir | Out-Null

$Files = @(
  "logo-32.png",
  "logo-32-white.png",
  "logo-32-black.png",
  "logo-128.png",
  "logo-256.png",
  "logo-512.png",
  "logo.ico"
)

foreach ($f in $Files) {
  $dest = Join-Path $AssetDir $f
  if (-not (Test-Path $dest) -or ((Get-Item $dest).Length -eq 0)) {
    Write-Host "Downloading missing asset: $f"
    Invoke-WebRequest -Uri "$BaseUrl/$f" -OutFile $dest -UseBasicParsing
  }
}

# Windows runner .ico used by Runner.rc
$RunnerRes = Join-Path $Root "app\windows\runner\resources"
New-Item -ItemType Directory -Force -Path $RunnerRes | Out-Null
Copy-Item -Force (Join-Path $AssetDir "logo.ico") (Join-Path $RunnerRes "app_icon.ico")

Write-Host "App assets OK under $AssetDir"
