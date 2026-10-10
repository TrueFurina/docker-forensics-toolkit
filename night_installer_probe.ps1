# night_installer_probe.ps1 - ELEVATED. Decisive test: does the installer survive
# past its fast-exit window when Docker Desktop is NOT running?
# If it survives, kill it BEFORE it replaces the working 4.94.0 installation.
$log = 'C:\Users\Lenovo\AppData\Local\Temp\night\installer_probe.log'
$exe = 'C:\Users\Lenovo\Downloads\DockerDesktopInstaller_new.exe'
$start = Get-Date
Set-Content $log ('PROBE start ' + $start.ToString('HH:mm:ss') + ' (Docker stopped)')

$p = Start-Process -FilePath $exe -ArgumentList 'install','--quiet','--accept-license' -PassThru
Add-Content $log ('launched pid=' + $p.Id)

$alive60 = $false
for ($i = 1; $i -le 12; $i++) {
  Start-Sleep -Seconds 5
  if ($p.HasExited) {
    Add-Content $log ('EXITED at t+' + ($i*5) + 's code=' + $p.ExitCode)
    break
  }
  # watch for Burn log creation (proof it got past early checks)
  $bl = Get-ChildItem "$env:TEMP" -Filter 'Docker*Installer*.log' -EA SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($bl) { Add-Content $log ('t+' + ($i*5) + 's Burn log exists: ' + $bl.Name + ' (' + $bl.Length + 'B)') }
  if ($i -eq 12) { $alive60 = $true }
}
if ($alive60) {
  Add-Content $log 'VERDICT=ALIVE_PAST_30s_WITH_DOCKER_STOPPED -> running-app-block CONFIRMED'
  Add-Content $log 'killing installer to protect the working 4.94.0 install (prevent 4.93 downgrade)'
  Start-Process C:\Windows\System32\taskkill.exe -ArgumentList '/F','/IM','DockerDesktopInstaller_new.exe','/T' -WindowStyle Hidden
  Start-Sleep -Seconds 3
}
Add-Content $log ('probe done ' + (Get-Date -Format 'HH:mm:ss'))
