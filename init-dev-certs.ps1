param(
  [string[]] $Hosts = @("admin.skoruba.local","admin-api.skoruba.local","sts.skoruba.local"),
  [string] $CertDir = ".\shared\nginx\certs",
  [switch] $Force
)

function Write-Title($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Fail($msg) { Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }

function Resolve-MkcertPath {
  # 1) Try in PATH
  $cmd = Get-Command mkcert -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  # 2) Try WinGet link
  $link = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links\mkcert.exe"
  if (Test-Path $link) { return $link }

  return $null
}

function Ensure-Mkcert {
  $mk = Resolve-MkcertPath
  if ($mk) { return $mk }

  Write-Host "mkcert not found. Trying winget..."
  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if ($winget) {
    winget source reset --force | Out-Null
    winget source update | Out-Null
    winget install -e --id FiloSottile.mkcert --accept-package-agreements --accept-source-agreements | Out-Null
    $mk = Resolve-MkcertPath
    if ($mk) { return $mk }
    Write-Host "mkcert still not found after winget."
  } else {
    Write-Host "winget not available."
  }

  # 3) Fallback: download mkcert.exe trực tiếp (chọn 1 version ổn định)
  Write-Host "Downloading mkcert fallback..."
  $tools = ".\tools\mkcert"
  New-Item -ItemType Directory -Path $tools -Force | Out-Null
  $dest = Join-Path $tools "mkcert.exe"
  $url  = "https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-windows-amd64.exe"
  try {
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
  } catch {
    Fail "Download mkcert failed: $($_.Exception.Message)"
  }
  if (!(Test-Path $dest)) { Fail "mkcert.exe not found after download." }
  return $dest
}

Write-Title "Locate/Install mkcert"
$MKCERT = Ensure-Mkcert
if (-not $MKCERT) { Fail "Cannot acquire mkcert." }
Write-Host "Using mkcert at: $MKCERT"

Write-Title "Trust local CA (mkcert -install)"
try { & $MKCERT -install | Out-Null } catch { Fail "mkcert -install failed: $($_.Exception.Message)" }

Write-Title "Ensure cert directory"
New-Item -ItemType Directory -Path $CertDir -Force | Out-Null

Write-Title "Generate certs per host"
foreach ($h in $Hosts) {
  $crtPath = Join-Path $CertDir "$h.crt"
  $keyPath = Join-Path $CertDir "$h.key"

  if ((Test-Path $crtPath) -and (Test-Path $keyPath) -and -not $Force) {
    Write-Host "Skip $h (already exists). Use -Force to overwrite."
    continue
  }

  Write-Host "Generating: $h"
  & $MKCERT $h | Out-Null

  $srcCrt = ".\${h}.pem"
  $srcKey = ".\${h}-key.pem"
  if ((-not (Test-Path $srcCrt)) -or (-not (Test-Path $srcKey))) {
    Fail "mkcert output not found for $h (expected $srcCrt and $srcKey)"
  }

  Copy-Item $srcCrt $crtPath -Force
  Copy-Item $srcKey $keyPath -Force
  Write-Host "OK -> $crtPath , $keyPath"
}

Write-Title "Copy public root CA for containers"
$caroot = (& $MKCERT -CAROOT)
$caSrc = Join-Path $caroot "rootCA.pem"
$caDst = Join-Path $CertDir "cacerts.crt"
Copy-Item $caSrc $caDst -Force
Write-Host "OK -> $caDst"

Write-Host "`nDone. Now run: docker compose up -d --build"
Write-Host "Tip: To use lvh.me domains (no hosts file), run with:"
Write-Host " .\init-dev-certs.ps1 -Hosts @('admin.lvh.me','admin-api.lvh.me','sts.lvh.me')"
