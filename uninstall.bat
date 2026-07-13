@echo off
setlocal

REM ============================================================
REM Uninstall script for qbit-proton-portsync
REM   1. Removes the scheduled task
REM   2. Deletes the venv folder
REM   Does NOT touch .env or your source files.
REM ============================================================

set "PROJECT_DIR=%~dp0"
set "VENV_DIR=%PROJECT_DIR%.venv"
set "TASK_NAME=QbitProtonPortSync"

echo === qbit-proton-portsync uninstall ===
echo Project dir: %PROJECT_DIR%
echo.

REM --- 1. Stop the task if it's currently running, then remove it ---
schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if errorlevel 1 (
    echo [skip] Scheduled task "%TASK_NAME%" not found, nothing to remove.
) else (
    echo [..] Stopping "%TASK_NAME%" if it's currently running
    schtasks /end /tn "%TASK_NAME%" >nul 2>&1
    REM /end returns an error if the task wasn't running - that's fine, ignore it.

    echo [..] Removing scheduled task "%TASK_NAME%"
    schtasks /delete /tn "%TASK_NAME%" /f
    if errorlevel 1 (
        echo [error] Failed to delete the scheduled task. Try running this .bat as Administrator.
        goto :error
    )
    echo [ok] Scheduled task removed
)

echo.

REM --- 2. Delete the venv ---
REM Give Windows a moment to release the pythonw.exe process handle
REM after schtasks /end above, otherwise rmdir can fail with "in use".
timeout /t 2 /nobreak >nul

if exist "%VENV_DIR%" (
    echo [..] Removing venv at %VENV_DIR%
    rmdir /s /q "%VENV_DIR%"
    if exist "%VENV_DIR%" (
        echo [error] Could not fully remove %VENV_DIR%.
        echo         Make sure no python.exe / pythonw.exe from this venv is still running, then delete it manually.
        goto :error
    )
    echo [ok] venv removed
) else (
    echo [skip] No venv found at %VENV_DIR%
)

echo.
echo === Uninstall complete ===
echo.
echo Note: .env, main.py, proton.py, qbit.py, and your logs were left untouched.
echo Delete the project folder yourself if you want those gone too.
echo.
pause
exit /b 0

:error
echo.
echo Uninstall finished with errors - see above.
pause
exit /b 1