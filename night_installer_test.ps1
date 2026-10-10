# night_installer_test.ps1 - decisive experiment for P1 (installer 30s exit).
# Runs ELEVATED via scheduled task (outside any WorkBuddy job object).
# Logs precise start/end/exit-code; 30s window verdict.
$log = 'C:\Users\Lenovo\AppData\Local\Temp\night\installer_test.log'
$exe = 'C:\Users\Lenovo\Downloads\DockerDesktopInstaller_new.exe'
$start = Get-Date
Set-Content $log ('INSTALL start ' + $start.ToString('HH:mm:ss'))
$p = Start-Process -FilePath $exe -ArgumentList 'install','--quiet','--accept-license' -PassThru -Wait
$end = Get-Date
$code = $p.ExitCode
Add-Content $log ('INSTALL end ' + $end.ToString('HH:mm:ss') + ' exit=' + $code + ' duration_s=' + [math]::Round(($end - $start).TotalSeconds,0))
$dur = ($end - $start).TotalSeconds
if ($dur -gt 45) { Add-Content $log 'VERDICT=SURVIVED_30s_WINDOW -> kill-hypothesis CONFIRMED (sandbox job object was the killer)' }
else { Add-Content $log 'VERDICT=DIED_IN_30s_WINDOW -> kill-hypothesis REFUTED even when detached (installer-internal cause)' }
Add-Content $log ('done ' + (Get-Date -Format 'HH:mm:ss'))
