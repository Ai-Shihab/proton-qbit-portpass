from pathlib import Path
from setuptools import setup

ROOT = Path(__file__).resolve().parent
requirements = ROOT.joinpath("requirements.txt").read_text().splitlines()
requirements = [r.strip() for r in requirements if r.strip() and not r.startswith("#")]

ENV_PATH = ROOT / ".env"

# Values left empty are meant to be filled in by hand. APP_LOG_PATH is
# pre-filled with an absolute path so the log file lands next to this
# project regardless of the working directory the service is launched from
# (important once it's run via a scheduled task / pythonw.exe).
ENV_SKELETON = {
    "QBIT_PATH": "C:/Program Files/qBittorrent/qbittorrent.exe",
    "RESTART_ENABLED": False,
    "QBIT_USERNAME": "your_qbittorent_username_here",
    "QBIT_PASSWORD": "your_qbittorent_password_here",
    "PROTON_LOG_PATH": "C:/Users/your_user_name/AppData/Local/Proton/Proton VPN/Logs/client-logs.txt",
    "APP_LOG_PATH": str(ROOT / "portsync.log"),
}


def create_env_file():
    if ENV_PATH.exists():
        print(f"[skip] {ENV_PATH} already exists, leaving it untouched")
        return

    with open(ENV_PATH, "w", encoding="utf-8") as f:
        for key, value in ENV_SKELETON.items():
            f.write(f'{key}="{value}"\n')

    print(f"[ok] Created {ENV_PATH} — fill in QBIT_USERNAME, QBIT_PASSWORD, and PROTON_LOG_PATH")


create_env_file()

setup(
    name="qbit-proton-portpass",
    version="1.1.0",
    description="Syncs qBittorrent's listen port with ProtonVPN's forwarded port",
    py_modules=["main", "proton", "qbit"],
    install_requires=requirements,
    python_requires=">=3.10",
)