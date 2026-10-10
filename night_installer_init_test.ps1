# night_installer_init_test.ps1 - zero-risk discriminator for exit=4 cause.
# Runs installer WITHOUT the install action (bare / --help / --version).
# If these also exit=4 fast -> stub early-init dies (framework-level).
# If they exit differently -> exit=4 is specific to the install path (e.g. version check).
$log = 'C:\Users\Lenovo\AppData\Local\Temp\night\installer_init_test.log'
$exe = 'C:\Users\Lenovo\Downloads\DockerDesktopInstaller_new.exe'
Set-Content $log ('INIT-TEST start ' + (Get-Date -Format 'HH:mm:ss'))

function Test-Invocation([string]$args, [string]$label) {
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  try {
    $p = Start-Process -FilePath $exe -ArgumentList $args -PassThru -WindowStyle Hidden
    $exited = $p.WaitForExit(20000)
    if ($exited) {
      Add-Content $log ($label + ': exit=' + $p.ExitCode + ' after ' + [math]::Round($sw.Elapsed.TotalSeconds,1) + 's')
    } else {
      Stop-Process -Id $p.Id -Force -EA SilentlyContinue
      Add-Content $log ($label + ': STILL RUNNING after 20s -> killed (stub stayed alive)')
    }
  } catch {
    Add-Content $log ($label + ': ERROR ' + $_.Exception.Message)
  }
}

Test-Invocation '' 'bare(no args)'
Test-Invocation '--help' 'help'
Test-Invocation '--version' 'version'
Add-Content $log ('INIT-TEST done ' + (Get-Date -Format 'HH:mm:ss'))
