import logging
import qbittorrentapi

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