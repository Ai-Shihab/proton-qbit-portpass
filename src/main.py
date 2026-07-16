import os
import sys
import time,psutil
import logging
import subprocess
from logging.handlers import RotatingFileHandler
from pathlib import Path

import qbittorrentapi
import requests
from dotenv import load_dotenv

from proton import tail_proton_port, proton_status
from qbit import ensure_logged_in, set_port, current_port,restart_qbit

# Load .env from the root directory
env_path = Path(__file__).resolve().parent.parent / '.env'
load_dotenv(dotenv_path=env_path)

log = logging.getLogger(__name__)


def setup_logging(log_file):
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    handler = RotatingFileHandler(log_file, maxBytes=1_000_000, backupCount=3)
    handler.setFormatter(logging.Formatter(
        "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
    ))
    logger.addHandler(handler)

    if sys.stdout is not None:
        console = logging.StreamHandler()
        console.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
        logger.addHandler(console)


def check_env():
    required = ["QBIT_USERNAME", "QBIT_PASSWORD", "PROTON_LOG_PATH","QBIT_PATH","RESTART_ENABLED"]
    missing = [v for v in required if not os.getenv(v)]
    if missing:
        raise SystemExit(f"Missing required .env values: {', '.join(missing)}")


def build_client():
    return qbittorrentapi.Client(
        host="127.0.0.1",
        port=8080,
        username=os.getenv("QBIT_USERNAME"),
        password=os.getenv("QBIT_PASSWORD"),
    )

def qbit_exit(timeout=60):
    start = time.time()

    while time.time() - start < timeout:
        if not any(
            p.info["name"] and p.info["name"].lower() == "qbittorrent.exe"
            for p in psutil.process_iter(["name"])
        ):
            return True

        time.sleep(0.5)

    return False

def main():
    check_env()
    log_path = os.getenv("PROTON_LOG_PATH")
    restart_stat = os.getenv("RESTART_ENABLED", "false").lower() == "true"
    qbit_path= os.getenv("QBIT_PATH")
    client = build_client()
    ensure_logged_in(client)
    log.info("Service started, watching %s", log_path)

    try:
        last_known_port = None
        for event in tail_proton_port(log_path, poll_interval=2):
            # Checking VPN status first, regardless of whether a port is configured
            if not proton_status():
                log.warning("Proton service not running, skipping")
                time.sleep(30)
                continue

            if event is None:
                continue  # heartbeat

            last_known_port = event

            try:
                if current_port(client) != last_known_port:
                    set_port(client, last_known_port)
                    time.sleep(5)
                    if restart_stat:
                        restart_qbit(client,qbit_path)
                else:
                    log.info("Proton port: %s [Unchanged]", last_known_port)
                    time.sleep(15)
            except (qbittorrentapi.APIConnectionError,
                     qbittorrentapi.Forbidden403Error,
                     qbittorrentapi.LoginFailed,
                     requests.exceptions.RequestException) as e:
                log.warning("qBittorrent unreachable or session invalid (%s), retrying login", e)
                try:
                    ensure_logged_in(client)
                    set_port(client, last_known_port)
                except Exception:
                    log.exception("Retry failed, will try again on next port change")
    except KeyboardInterrupt:
        log.info("Shutting down")
        raise
    finally:
        try:
            client.auth_log_out()
        except Exception:
            pass


if __name__ == "__main__":
    setup_logging(os.getenv("APP_LOG_PATH", "portsync.log"))
    while True:
        try:
            main()
            break  # clean exit, e.g. Ctrl+C
        except KeyboardInterrupt:
            break
        except Exception:
            log.exception("Unhandled error, restarting in 30s")
            time.sleep(30)