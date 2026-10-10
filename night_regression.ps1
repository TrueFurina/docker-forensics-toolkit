# night_regression.ps1 - full regression build OUTSIDE any WorkBuddy job object
# (launched via scheduled task / WMI; parent is not in the sandbox job tree).
# v2: per-run status filename (no shared-file races), PASS requires the image to exist.
$ErrorActionPreference = 'Continue'
$dir = 'C:\Users\Lenovo\AppData\Local\Temp\night'
$stamp = Get-Date -Format 'HHmmss'
$st = Join-Path $dir ('reg_status_' + $stamp + '.txt')
$bl = Join-Path $dir ('reg_build_' + $stamp + '.log')
$dk = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe'
$bx = 'C:\Program Files\Docker\Docker\resources\cli-plugins\docker-buildx.exe'
Set-Content $st ('REG start ' + (Get-Date -Format 'HH:mm:ss'))

function Test-Engine {
  $o = & $dk version --format '{{.Server.Version}}' 2>$null
  return ($LASTEXITCODE -eq 0 -and ("$o" -match '^2\d'))
}

if (-not (Test-Engine)) {
  Add-Content $st ('engine down, starting ' + (Get-Date -Format 'HH:mm:ss'))
  Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
  $ok = $false
  for ($i = 1; $i -le 20; $i++) {
    Start-Sleep -Seconds 15
    if (Test-Engine) { $ok = $true; Add-Content $st ('engine ready after ' + ($i * 15) + 's'); break }
  }
  if (-not $ok) { Add-Content $st 'RESULT=FAIL engine_not_ready'; exit 1 }
} else {
  Add-Content $st 'engine already ready'
}

Add-Content $st ('BUILD start ' + (Get-Date -Format 'HH:mm:ss'))
Push-Location 'E:\Program\MARL\study-help-pro'
& $bx build --load -t mangdehenzhi/app:1.0.1 -f Dockerfile . > $bl 2>&1
$rc = $LASTEXITCODE
Pop-Location
Add-Content $st ('BUILD exit=' + $rc + ' at ' + (Get-Date -Format 'HH:mm:ss'))

$img = (& $dk images --format '{{.Repository}}:{{.Tag}} {{.Size}}' 2>$null | Select-String 'mangdehenzhi/app:1.0.1') -join '; '
Add-Content $st ('IMAGE ' + $img)
if ($rc -eq 0 -and $img) { Add-Content $st 'RESULT=PASS' } else {
  Add-Content $st '--- build log tail ---'
  Get-Content $bl -Tail 20 -ErrorAction SilentlyContinue | ForEach-Object { Add-Content $st $_ }
  Add-Content $st 'RESULT=FAIL'
}
Add-Content $st ('REG done ' + (Get-Date -Format 'HH:mm:ss'))
