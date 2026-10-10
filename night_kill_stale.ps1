# night_kill_stale.ps1 - kill stale regression pwsh/buildx/build-client processes only.
$ErrorActionPreference = 'Continue'
Add-Content 'C:\Users\Lenovo\AppData\Local\Temp\night\kill_stale.log' ('run ' + (Get-Date -Format 'HH:mm:ss'))
Get-CimInstance Win32_Process -Filter "Name='pwsh.exe'" |
  Where-Object { $_.CommandLine -match 'night_regression|night_verify' } |
  ForEach-Object {
    Add-Content 'C:\Users\Lenovo\AppData\Local\Temp\night\kill_stale.log' ('kill pwsh pid=' + $_.ProcessId)
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
  }
foreach ($n in 'docker-buildx','com.docker.build') {
  Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
    Add-Content 'C:\Users\Lenovo\AppData\Local\Temp\night\kill_stale.log' ('kill ' + $n + ' pid=' + $_.Id)
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
  }
}
Add-Content 'C:\Users\Lenovo\AppData\Local\Temp\night\kill_stale.log' ('done ' + (Get-Date -Format 'HH:mm:ss'))
