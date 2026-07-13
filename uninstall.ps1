# --- Self-Elevate to Administrator ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}
# -------------------------------------

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

# 3. Clean up generated files and build folders
$ItemsToRemove = @(
    "start_service.ps1",
    "stop_service.ps1",
    "build",
    ".git",
    "*.egg-info"
)

foreach ($Item in $ItemsToRemove) {
    $TargetPath = Join-Path $ProjectDir $Item
    if (Test-Path $TargetPath) {
        Write-Host "[..] Deleting $Item..."
        Remove-Item -Path $TargetPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[ok] $Item deleted."
    }
}

Write-Host "`n=== Uninstall complete ==="
Write-Host "Your .env file, portsync.log, and source code files have been left untouched."
Write-Host "You can safely delete this entire project folder now if you wish."

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")