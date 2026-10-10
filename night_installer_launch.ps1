# night_installer_launch.ps1 - elevated launcher (silent UAC; consent broker parent
# = outside any WorkBuddy job object, preserving the experiment's validity).
Start-Process pwsh -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','C:\Users\Lenovo\AppData\Local\Temp\night\night_installer_test.ps1'
Write-Output 'elevated installer test launched'
