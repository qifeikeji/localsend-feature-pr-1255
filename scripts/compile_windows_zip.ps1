# UNCOMMENT THESE LINES TO BUILD FROM LATEST COMMIT
# git reset --hard origin/main
# git pull

$Root = Split-Path -Parent $PSScriptRoot
Set-Location (Join-Path $Root "app")

& (Join-Path $Root "scripts\ensure_app_assets.ps1")

fvm flutter clean
fvm flutter pub get
fvm flutter pub run build_runner build -d
fvm flutter build windows --release --no-tree-shake-icons

& (Join-Path $Root "scripts\verify_windows_bundle.ps1")

$release = "build\windows\x64\runner\Release"
if (-not (Test-Path $release)) {
  $release = "build\windows\runner\Release"
}
if (-not (Test-Path $release)) {
  throw "Windows Release folder not found after build."
}

echo {} | Out-File -Encoding utf8 (Join-Path $release "settings.json")

$version = (Select-String -Path pubspec.yaml -Pattern '^version: ([0-9.]+)' | ForEach-Object { $_.Matches.Groups[1].Value })
$zip = "LocalSend-$version-windows-x86-64.zip"
Compress-Archive -Path (Join-Path $release "*") -DestinationPath $zip -Force

Write-Output "Generated Windows zip: $zip"
