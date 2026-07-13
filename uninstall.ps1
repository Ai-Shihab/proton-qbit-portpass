$TaskName = "QbitProtonPortSync"
$ProjectDir = $PSScriptRoot
$VenvDir = Join-Path $ProjectDir ".venv"

Write-Host "=== Uninstalling qbit-proton-portsync ==="

# 1. Stop and remove the scheduled task
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Write-Host "[..] Stopping scheduled task '$TaskName' (if running)..."
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    Write-Host "[..] Removing scheduled task '$TaskName'..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "[ok] Task removed."
} else {
    Write-Host "[skip] Scheduled task '$TaskName' not found."
}

# 2. Delete the .venv folder
if (Test-Path $VenvDir) {
    Write-Host "[..] Deleting virtual environment at $VenvDir..."
    Remove-Item -Path $VenvDir -Recurse -Force
    Write-Host "[ok] .venv deleted."
} else {
    Write-Host "[skip] .venv folder not found."
}

Write-Host "`n=== Uninstall complete ==="
Write-Host "Your .env file, portsync.log, and source files have been left untouched."
Write-Host "You can safely delete this entire project folder now if you wish."

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")