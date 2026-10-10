# night_verify.ps1 - wait for regression build RESULT, then auto-verify container.
# Runs outside any job object (launched via scheduled task).
$ErrorActionPreference = 'Continue'
$dir = 'C:\Users\Lenovo\AppData\Local\Temp\night'
$dk = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe'
$st = Join-Path $dir 'verify_status.txt'
Set-Content $st ('VERIFY start ' + (Get-Date -Format 'HH:mm:ss'))

# 1. wait up to 40 min for latest reg_status file to contain RESULT=
$f = $null
$done = $false
for ($i = 1; $i -le 240; $i++) {
  Start-Sleep -Seconds 10
  $f = Get-ChildItem (Join-Path $dir 'reg_status_*.txt') -ErrorAction SilentlyContinue |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($f -and (Select-String -Path $f.FullName -Pattern '^RESULT=' -Quiet)) { $done = $true; break }
}
if (-not $done) { Add-Content $st 'RESULT=WAIT_TIMEOUT build_still_running_after_40min'; exit 1 }

$res = (Select-String -Path $f.FullName -Pattern '^RESULT=(\w+)').Matches[0].Groups[1].Value
Add-Content $st ('build RESULT=' + $res + ' at ' + (Get-Date -Format 'HH:mm:ss'))
if ($res -ne 'PASS') { Add-Content $st 'RESULT=VERIFY_SKIPPED build_failed'; exit 1 }

# 2. run verify container from the new image
& $dk rm -f regverify 2>$null | Out-Null
$r = & $dk run -d --name regverify -p 18002:8002 mangdehenzhi/app:1.0.1 2>&1
Add-Content $st ('run: ' + (($r | Out-String).Trim()))
Start-Sleep -Seconds 30
$s = (& $dk ps --filter name=regverify --format '{{.Status}}') -join '; '
Add-Content $st ('container: ' + $s)

# 3. health checks: inside container (curl) and from host (mapped port)
$inApi  = (& $dk exec regverify curl -s -o NUL -w '%{http_code}' http://localhost:8002/api/status 2>&1) -join ''
$inHome = (& $dk exec regverify curl -s -o NUL -w '%{http_code}' http://localhost:8002/ 2>&1) -join ''
Add-Content $st ('in-container api/status=' + $inApi + ' home=' + $inHome)

$hostApi  = & C:\Windows\System32\curl.exe -s -o NUL -w '%{http_code}' http://localhost:18002/api/status 2>&1
$hostHome = & C:\Windows\System32\curl.exe -s -o NUL -w '%{http_code}' http://localhost:18002/ 2>&1
Add-Content $st ('host api/status=' + $hostApi + ' home=' + $hostHome)

if ("$inApi" -eq '200' -and "$hostApi" -eq '200') { Add-Content $st 'RESULT=VERIFY_PASS' }
else { Add-Content $st 'RESULT=VERIFY_FAIL' }
Add-Content $st ('VERIFY done ' + (Get-Date -Format 'HH:mm:ss'))
