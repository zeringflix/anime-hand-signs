# Run from the clone, with Studio already open. No background service is installed.
Set-Location (Resolve-Path (Join-Path $PSScriptRoot ".."))
py tools\ai_runner.py --check
if ($LASTEXITCODE -ne 0) { throw "Preflight failed; see tools/SETUP.md" }
Write-Host "Preflight completed. To run approved tasks, consult tools/SETUP.md."
