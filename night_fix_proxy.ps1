# night_fix_proxy.ps1 - clear dead proxy 7890 from Docker Desktop settings.
# MUST run while Docker Desktop is NOT running (it rewrites settings from memory on exit).
$p = 'C:\Users\Lenovo\AppData\Roaming\Docker\settings-store.json'
$raw = Get-Content $p -Raw
$raw = $raw.Replace('http://127.0.0.1:7890', '')
$raw = $raw.Replace('127.0.0.1:7890', '')
$raw = $raw -replace '"ProxyHTTPMode"\s*:\s*"manual"', '"ProxyHTTPMode": "system"'
Set-Content -Path $p -Value $raw -Encoding UTF8
try {
  $chk = Get-Content $p -Raw | ConvertFrom-Json
  Write-Output ("JSON OK mode=" + $chk.ProxyHTTPMode)
} catch {
  Write-Output ("JSON BROKEN: " + $_.Exception.Message)
}
$n = (Select-String -InputObject (Get-Content $p -Raw) -Pattern '7890' -AllMatches).Matches.Count
Write-Output ("7890 remaining: " + $n)
