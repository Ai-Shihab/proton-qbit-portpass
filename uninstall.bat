@echo off
setlocal

REM ============================================================
REM Setup script for qbit-proton-portsync
REM   1. Creates a venv (if it doesn't already exist)
REM   2. Activates it and installs the project + dependencies
REM   3. Registers a scheduled task to run main.py silently at logon
REM ============================================================

set "PROJECT_DIR=%~dp0"
set "VENV_DIR=%PROJECT_DIR%.venv"
set "TASK_NAME=QbitProtonPortSync"

echo === qbit-proton-portsync setup ===
echo Project dir: %PROJECT_DIR%
echo.

REM --- 1. Create venv if missing ---
if exist "%VENV_DIR%\Scripts\python.exe" (
    echo [skip] venv already exists at %VENV_DIR%
) else (
    echo [..] Creating venv at %VENV_DIR%
    python -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo [error] Failed to create venv. Is Python installed and on PATH?
        goto :error
    )
)

REM --- 2. Activate venv ---
call "%VENV_DIR%\Scripts\activate.bat"
if errorlevel 1 (
    echo [error] Failed to activate venv.
    goto :error
)

REM --- 3. Upgrade packaging tools and install the project ---
echo [..] Upgrading pip, setuptools, wheel
python -m pip install --upgrade pip setuptools wheel
if errorlevel 1 (
    echo [error] Failed to upgrade pip/setuptools/wheel.
    goto :error
)

echo [..] Installing project and dependencies
python -m pip install "%PROJECT_DIR%."
if errorlevel 1 (
    echo [error] pip install failed.
    goto :error
)

set "PYTHONW_EXE=%VENV_DIR%\Scripts\pythonw.exe"
set "MAIN_SCRIPT=%PROJECT_DIR%main.py"
set "RUNNER_BAT=%PROJECT_DIR%_run_service.bat"

echo [..] Writing task runner %RUNNER_BAT%
(
    echo @echo off
    echo cd /d "%PROJECT_DIR%"
    echo start "" "%PYTHONW_EXE%" "%MAIN_SCRIPT%"
) > "%RUNNER_BAT%"

echo [..] Registering scheduled task "%TASK_NAME%"
schtasks /create /tn "%TASK_NAME%" ^
    /tr "\"%RUNNER_BAT%\"" ^
    /sc onlogon ^
    /rl limited ^
    /f

if errorlevel 1 (
    echo [error] Failed to create scheduled task. Try running this .bat as Administrator.
    goto :error
)

echo.
echo === Setup complete ===
echo.
echo IMPORTANT: open .env in %PROJECT_DIR% and fill in
echo   QBIT_USERNAME, QBIT_PASSWORD, and PROTON_LOG_PATH
echo before the task next runs (or log off/on to trigger it now).
echo.
echo To remove the scheduled task later:
echo   schtasks /delete /tn "%TASK_NAME%" /f
echo.
pause
exit /b 0

:error
echo.
echo Setup failed - see the error above.
pause
exit /b 1