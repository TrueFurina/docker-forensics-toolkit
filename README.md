# docker-forensics-toolkit

Diagnostic & repair scripts from a real Windows incident: a Docker engine that
died "politely" (all processes exit 0x0 in the same second), an installer that
silently quit with exit=4, and SIGBUS crashes under build load.

Companion write-up (Chinese): [Docker 引擎连环死亡排查实录](https://github.com/TrueFurina/docker-detective-story) (see Desktop repo for the full four-act post-mortem).

## Scripts

| Script | Purpose |
|--------|---------|
| `night_fix_proxy.ps1` | Clear dead proxy (7890) from Docker Desktop settings — must run while Docker is NOT running (it rewrites settings from memory on exit) |
| `night_regression.ps1` | Full regression build launched OUTSIDE any third-party job object (scheduled task / WMI parent) |
| `night_verify.ps1` | Wait for regression build RESULT, then auto-verify container health |
| `night_kill_stale.ps1` | Kill only stale regression pwsh/buildx processes |
| `night_installer_init_test.ps1` | Zero-risk discriminator for installer exit=4 (bare invocation, no install action) |
| `night_installer_probe.ps1` | Test: does the installer survive past its fast-exit window when Docker is not running? |
| `night_installer_test.ps1` | Elevated installer experiment via scheduled task (outside job object) |
| `night_installer_launch.ps1` | Elevated launcher (silent UAC; consent-broker parent) |
| `night_installer_494_test.ps1` | Same-version reinstall test (4.94.0 over 4.94.0) |

## Key lessons baked into these scripts

1. **Exit codes are testimony** — all-0x0 group exit = graceful close = an active scheduler sent the kill.
2. **Audit chain beats guesswork** — Windows 4688/4689 process audit identifies the killer directly.
3. **Immunity = leaving the job object**, not asking the killer to stop.
4. **Docker Desktop rewrites settings from memory on exit** — kill it first, then edit.
5. **Invalid settings keys are silently ignored** — verify key names from binary struct tags.

All scripts audited: no credentials, no tokens, no host-specific secrets.
