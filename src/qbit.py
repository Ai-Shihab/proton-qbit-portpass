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


def restart_qbit(client,path):
    proc = None
    for p in psutil.process_iter(["name"]):
        if p.info["name"] and p.info["name"].lower() == "qbittorrent.exe":
            proc = p
            break

    if proc is None:
        log.error("qBittorrent is not running")
    log.info("Shutting down Qbittorrent")
    client.app.shutdown()

    # Wait up to 60 s
    try:
        proc.wait(timeout=15)   # Wait up to 15 seconds
    except psutil.TimeoutExpired:
        log.warning("Graceful Qbit shutdown failed, Killing the process")
        proc.kill()             # Force kill
        proc.wait()
    subprocess.Popen([path])
    log.info("Qbit restarted")
    time.sleep(5)
    client.auth_log_in()