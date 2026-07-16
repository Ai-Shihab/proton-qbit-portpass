import logging
import qbittorrentapi
import subprocess,time,psutil

log = logging.getLogger(__name__)


def ensure_logged_in(client):
    try:
        client.auth_log_in()
    except qbittorrentapi.LoginFailed as e:
        log.error("qBittorrent login failed: %s", e)
        raise


def current_port(client):
    return client.app.preferences.listen_port


def set_port(client, port):
    client.app.set_preferences({"listen_port": port})
    log.info("Updated qBittorrent listen_port -> %s", port)

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

def restart_qbit(client,path):
    client.app.shutdown()
    
    if qbit_exit():
        subprocess.Popen([
            path,
            "--no-splash"
        ])
    time.sleep(10)
    log.info("qBittorrent restarted")
    client.auth_log_in()