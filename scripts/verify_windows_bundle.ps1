# Fails CI if the Windows Release folder is missing Flutter assets (icons + images).
param(
  [string]$AppDir = "app"
)

$ErrorActionPreference = "Stop"

$releaseX64 = Join-Path $AppDir "build\windows\x64\runner\Release"
$releaseLegacy = Join-Path $AppDir "build\windows\runner\Release"
$release = if (Test-Path $releaseX64) { $releaseX64 } elseif (Test-Path $releaseLegacy) { $releaseLegacy } else {
  throw "Windows Release output not found. Expected: $releaseX64"
}

$flutterAssets = Join-Path $release "data\flutter_assets"
if (-not (Test-Path $flutterAssets)) {
  throw "Missing data\flutter_assets — zip path is likely wrong or build failed."
}

$iconFont = Get-ChildItem -Path $flutterAssets -Recurse -Filter "MaterialIcons*.otf" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $iconFont) {
  throw "MaterialIcons font missing from flutter_assets (UI icons will not render)."
}

$manifestPath = Join-Path $flutterAssets "AssetManifest.json"
if (-not (Test-Path $manifestPath)) {
  throw "AssetManifest.json missing."
}
$manifest = Get-Content $manifestPath -Raw
if ($manifest -notmatch "logo-512") {
  throw "logo-512.png not in AssetManifest — image assets were not bundled."
}

$exe = Get-ChildItem -Path $release -Filter "*.exe" | Select-Object -First 1
$sizeMb = [math]::Round((Get-ChildItem $release -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
Write-Host "Windows bundle OK: $($exe.Name), ${sizeMb} MB total, icons font: $($iconFont.Name)"
