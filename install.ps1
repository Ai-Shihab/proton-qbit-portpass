$ErrorActionPreference = "Stop"

# Get current script directory
$ProjectDir = $PSScriptRoot
$VenvDir = Join-Path $ProjectDir ".venv"
$TaskName = "QbitProtonPortSync"

Write-Host "=== qbit-proton-portsync setup ==="
Write-Host "Project dir: $ProjectDir`n"

# 1. Create venv if missing
$PythonExe = Join-Path $VenvDir "Scripts\python.exe"
if (Test-Path $PythonExe) {
    Write-Host "[skip] venv already exists at $VenvDir"
} else {
    Write-Host "[..] Creating venv at $VenvDir"
    python -m venv $VenvDir
}

# 2. Upgrade packaging tools and install the project
Write-Host "[..] Upgrading pip, setuptools, wheel"
& $PythonExe -m pip install --upgrade pip setuptools wheel

Write-Host "[..] Installing project and dependencies"
& $PythonExe -m pip install "$ProjectDir"

# 3. Register Scheduled Task using PowerShell cmdlets
Write-Host "[..] Registering scheduled task '$TaskName'"

$PythonwExe = Join-Path $VenvDir "Scripts\pythonw.exe"
$MainScript = Join-Path $ProjectDir "main.py"

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$Action = New-ScheduledTaskAction -Execute $PythonwExe -Argument "`"$MainScript`"" -WorkingDirectory $ProjectDir
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -ExecutionTimeLimit (New-TimeSpan -Days 0)

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Syncs qBittorrent port with ProtonVPN" | Out-Null

# 4. Generate the Start and Stop scripts
Write-Host "[..] Generating helper scripts..."

$StartScriptContent = @"
`$TaskName = "$TaskName"

Write-Host "Attempting to start task: `$TaskName..."

if (Get-ScheduledTask -TaskName `$TaskName -ErrorAction SilentlyContinue) {
    Start-ScheduledTask -TaskName `$TaskName
    Write-Host "`n[Success] The background service has been started!"
    Write-Host "Check portsync.log in your project directory to confirm it's running correctly."
} else {
    Write-Host "`n[Error] Task '`$TaskName' not found. Please run install.ps1 first."
}

Write-Host "`nPress any key to exit..."
`$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
"@

$StopScriptContent = @"
`$TaskName = "$TaskName"

Write-Host "Attempting to stop task: `$TaskName..."

if (Get-ScheduledTask -TaskName `$TaskName -ErrorAction SilentlyContinue) {
    Stop-ScheduledTask -TaskName `$TaskName -ErrorAction SilentlyContinue
    Write-Host "`n[Success] The background service has been stopped!"
} else {
    Write-Host "`n[Error] Task '`$TaskName' not found. Is it installed?"
}

Write-Host "`nPress any key to exit..."
`$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
"@

Set-Content -Path (Join-Path $ProjectDir "start_service.ps1") -Value $StartScriptContent -Encoding UTF8
Set-Content -Path (Join-Path $ProjectDir "stop_service.ps1") -Value $StopScriptContent -Encoding UTF8
Write-Host "[ok] Created start_service.ps1 and stop_service.ps1."

Write-Host "`n=== Setup complete ==="
Write-Host "IMPORTANT: Open .env in $ProjectDir and fill in"
Write-Host "  QBIT_USERNAME, QBIT_PASSWORD, and PROTON_LOG_PATH"
Write-Host "`nOnce configured, run 'start_service.ps1' to trigger the task immediately."
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")