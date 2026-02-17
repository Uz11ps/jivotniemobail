"""
Переключает pm2 process deti-admin на Next.js админку из /root/deti-admin.

Требования:
  pip install paramiko

ENV:
  DEPLOY_HOST, DEPLOY_PORT, DEPLOY_USER, DEPLOY_PASSWORD
  DEPLOY_REMOTE_DIR (optional, default /root/deti-admin)
"""

from __future__ import annotations

import os
import sys

import paramiko


def _safe_print(text: str) -> None:
    enc = getattr(sys.stdout, "encoding", None) or "utf-8"
    safe = text.encode(enc, errors="replace").decode(enc, errors="replace")
    print(safe)


def main() -> int:
    host = os.getenv("DEPLOY_HOST", "")
    user = os.getenv("DEPLOY_USER", "")
    password = os.getenv("DEPLOY_PASSWORD", "")
    port = int(os.getenv("DEPLOY_PORT", "22"))
    remote_dir = os.getenv("DEPLOY_REMOTE_DIR", "/root/deti-admin")

    if not host or not user or not password:
        print("Missing DEPLOY_HOST/DEPLOY_USER/DEPLOY_PASSWORD env vars.")
        return 2

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, port, user, password)

    def run(cmd: str, check: bool = True) -> None:
        _safe_print("\nREMOTE: " + cmd)
        _, stdout, stderr = ssh.exec_command(cmd)
        code = stdout.channel.recv_exit_status()
        out = stdout.read().decode(errors="replace")
        err = stderr.read().decode(errors="replace")
        if out.strip():
            _safe_print("OUT:\n" + out.strip())
        if err.strip():
            _safe_print("ERR:\n" + err.strip())
        if check and code != 0:
            raise RuntimeError(f"Command failed [{code}]: {cmd}")

    # 1) Stop/remove old deti-admin if it points to old script.
    run("pm2 describe deti-admin | head -n 40 || true", check=False)
    run("pm2 delete deti-admin || true", check=False)

    # 2) Start Next.js admin from ecosystem config in remote_dir.
    run(f"test -f {remote_dir}/ecosystem.config.js", check=True)
    run(f"cd {remote_dir} && pm2 start ecosystem.config.js", check=True)
    run("pm2 save || true", check=False)
    run("pm2 status deti-admin || pm2 status", check=False)

    # 3) Verify that port 3000 now serves Next (__next).
    run("curl -s http://127.0.0.1:3000/ | head -n 30", check=False)

    ssh.close()
    _safe_print("\nOK: pm2 switched to Next.js admin.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

