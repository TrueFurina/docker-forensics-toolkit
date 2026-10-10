# night_installer_494_test.ps1 - ELEVATED. Decisive test #3: SAME-VERSION install
# (4.94.0 over 4.94.0). If downgrade-block is the exit=4 cause, this survives the
# 30s window and completes. Let it run to completion (no kill) - official
# registration also repairs the protocol handler (P2).
$log = 'C:\Users\Lenovo\AppData\Local\Temp\night\installer_494_test.log'
$exe = 'D:\DockerDesktopInstaller_4.94.0.exe'
$start = Get-Date
Set-Content $log ('INSTALL-494 start ' + $start.ToString('HH:mm:ss'))
$p = Start-Process -FilePath $exe -ArgumentList 'install','--quiet','--accept-license' -PassThru
Add-Content $log ('launched pid=' + $p.Id)
$milestone30 = $false
for ($i = 1; $i -le 120; $i++) {
  Start-Sleep -Seconds 5
  if ($p.HasExited) {
    Add-Content $log ('EXITED at t+' + ($i*5) + 's code=' + $p.ExitCode)
    break
  }
  if ($i -eq 6) { Add-Content $log 't+30s STILL ALIVE (past the killer window!)' }
  if ($i -eq 12) { $milestone30 = $true; Add-Content $log 't+60s STILL ALIVE' }
  if ($i -ge 120) { break }
}
if (-not $p.HasExited) {
  Add-Content $log 'waiting for installer to finish (up to 20 more minutes)...'
  $done = $p.WaitForExit(1200000)
  if ($done) { Add-Content $log ('EXITED code=' + $p.ExitCode + ' total_min=' + [math]::Round(((Get-Date)-$start).TotalMinutes,1)) }
  else { Add-Content $log 'TIMEOUT 20min - killing'; Start-Process taskkill.exe -ArgumentList '/F','/PID',$p.Id,'/T' }
}
if ($milestone30) { Add-Content $log 'VERDICT=SURVIVED_30s -> downgrade-block CONFIRMED as exit=4 root cause' }
Add-Content $log ('done ' + (Get-Date -Format 'HH:mm:ss'))
