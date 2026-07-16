# qbit-proton-portsync

Keeps qBittorrent's listen port in sync with ProtonVPN's forwarded port — automatically, in the background, on Windows.

ProtonVPN periodically rotates the forwarded port it assigns you (roughly once an hour while connected). If qBittorrent's listen port doesn't match, your incoming connectivity silently breaks until you notice and fix it by hand. This script watches Proton's log file for new port assignments and pushes them into qBittorrent via its Web API — no manual intervention required.

## Features

- Watches ProtonVPN's log file in real time and detects new forwarded ports as they're assigned
- Pushes the new port to qBittorrent automatically via the WebUI API
- Checks that the ProtonVPN service is actually running before acting, so it doesn't act on stale log data
- Recovers from log file rotation/truncation and expired/dropped qBittorrent sessions without crashing
- Self-healing: unhandled errors trigger an automatic restart with backoff instead of leaving the service dead
- Rotating log file, so disk usage stays bounded even running 24/7
- Runs silently at logon via Windows Task Scheduler — no visible console window
- Automatic restart on port update which kills the delay inherent from port change

## Requirements

- Windows, with ProtonVPN (desktop client) and qBittorrent installed
- Python 3.8+
- qBittorrent's WebUI enabled (Tools → Options → Web UI), reachable at `127.0.0.1:8080`

## Installation

### Automated (recommended)

1. Download or clone this repository.
2. Run as **administrator** `install.ps1`.
3. Fill out your info in .env
4. RESTART_ENABLED=True will restart qbittorrent to kill the delay
5. use `start_service.ps1` and `stop_service.ps1` scripts

This will:
- Create a Python virtual environment (`.venv`) in the project folder
- Install the project and its dependencies into that venv
- Generate a `.env` file with an empty skeleton for you to fill in
- Register a Windows Scheduled Task that runs the service silently at logon

After it finishes, open `.env` and fill in your qBittorrent credentials and Proton log path (see [Configuration](#configuration)).

### Manual

```bat
python -m venv .venv
.venv\Scripts\activate
python -m pip install --upgrade pip setuptools wheel
pip install .
```

Then create a `.env` file yourself (see [Configuration](#configuration)) and run:

```bat
python main.py
```

## Configuration

All configuration lives in a `.env` file in the project root:

| Variable          | Description                                                                 |
|-------------------|------------------------------------------------------------------------------|
| `QBIT_USERNAME`    | qBittorrent WebUI username                                                   |
| `QBIT_PASSWORD`    | qBittorrent WebUI password                                                   |
| `PROTON_LOG_PATH`  | Absolute path to ProtonVPN's log file, e.g. `C:/Users/<you>/AppData/Local/Proton/Proton VPN/Logs/client-logs.txt` |
| `APP_LOG_PATH`     | Where this service writes its own log (auto-set to an absolute path by `setup.py`) |

## Running

- **As a background service (recommended):** handled automatically by `install.ps1` — the task runs at logon using `pythonw.exe`, so no console window appears.
- **Manually, in a terminal:**
  ```bat
  .venv\Scripts\activate
  python main.py
  ```
  Press `Ctrl+C` to stop.

## Logs

Logs are written to the path set in `APP_LOG_PATH` (default: `portsync.log` in the project folder), and rotate automatically once they reach 1 MB (keeping 3 backups). Check this file first if the service doesn't seem to be updating the port.

## Uninstalling

Double-click `uninstall.ps1`. This will:
- Stop the scheduled task if it's currently running
- Remove the scheduled task
- Delete the `.venv` folder

Your `.env` file, logs, and source files are left untouched — delete the project folder yourself if you want those gone too.


## License
MIT
