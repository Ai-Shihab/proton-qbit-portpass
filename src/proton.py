import re
import os
import time
import logging
import psutil

log = logging.getLogger(__name__)


def tail_proton_port(path, poll_interval=0.5):
    f = open(path, encoding="utf-8", errors="ignore")
    f.seek(0, 2)  # start at end of file
    inode = os.fstat(f.fileno()).st_ino

    while True:
        line = f.readline()
        if not line:
            time.sleep(poll_interval)
            # Check whether the file has been rotated or truncated
            try:
                st = os.stat(path)
                if st.st_ino != inode or st.st_size < f.tell():
                    log.info("Proton log file rotated/truncated, reopening")
                    f.close()
                    f = open(path, encoding="utf-8", errors="ignore")
                    inode = os.fstat(f.fileno()).st_ino
                    f.seek(0, 2)
            except FileNotFoundError:
                log.warning("Proton log file missing, will retry")
            yield None  # heartbeat: no new port
            continue

        m = re.search(r"Port pair (\d+)->\d+", line)
        if m:
            port = int(m.group(1))
            # log.info("Proton port: %s", port)
            yield port


def proton_status():
    try:
        return psutil.win_service_get("ProtonVPN WireGuard").status() == "running"
    except psutil.NoSuchProcess:
        return False