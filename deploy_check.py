"""
Быстрая проверка сервера после деплоя.

Требования:
  pip install paramiko

ENV:
  DEPLOY_HOST, DEPLOY_PORT, DEPLOY_USER, DEPLOY_PASSWORD
"""

from __future__ import annotations

import os
import sys

import paramiko


def _safe_print_block(label: str, text: str) -> None:
    # В Windows-консоли часто cp1251; pm2 рисует псевдографику.
    # Печатаем с replace, чтобы не падать на UnicodeEncodeError.
    enc = getattr(sys.stdout, "encoding", None) or "utf-8"
    safe = text.encode(enc, errors="replace").decode(enc, errors="replace")
    if safe.strip():
        print(f"{label}:\n{safe.strip()}")


def main() -> int:
    host = os.getenv("DEPLOY_HOST", "")
    user = os.getenv("DEPLOY_USER", "")
    password = os.getenv("DEPLOY_PASSWORD", "")
    port = int(os.getenv("DEPLOY_PORT", "22"))

    if not host or not user or not password:
        print("Missing DEPLOY_HOST/DEPLOY_USER/DEPLOY_PASSWORD env vars.")
        return 2

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, port, user, password)

    cmds = [
        "pm2 status deti-admin || pm2 status",
        "echo '--- PM2 DESCRIBE ---'; pm2 describe deti-admin | head -n 60 || true",
        "echo '--- ECOSYSTEM ---'; sed -n '1,120p' /root/deti-admin/ecosystem.config.js || true",
        "echo '--- BACKUPS ---'; ls -d /root/deti-admin_backup_* 2>/dev/null | tail -n 10 || true",
        "echo '--- NEXT BIN IN BACKUPS ---'; for d in /root/deti-admin_backup_*; do if [ -e \"$d/node_modules/.bin/next\" ]; then echo \"HAS next: $d\"; fi; done || true",
        "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000/ || true; echo",
        "echo '--- HEAD 3000 ---'; curl -s http://127.0.0.1:3000/ | head -n 12 || true",
        "echo '--- HEAD 80 ---'; curl -s http://127.0.0.1/ | head -n 12 || true",
        "echo '--- LISTEN ---'; ss -lntp | head -n 40 || true",
        "echo '--- DETI-ADMIN LS ---'; ls -la /root/deti-admin | head -n 60 || true",
        "echo '--- PACKAGE.JSON ---'; (test -f /root/deti-admin/package.json && sed -n '1,80p' /root/deti-admin/package.json) || echo 'NO package.json'",
        "echo '--- NEXT SRC CHECK ---'; (test -f /root/deti-admin/src/app/page.tsx && echo 'HAS src/app/page.tsx') || echo 'NO src/app/page.tsx'",
    ]

    for cmd in cmds:
        print("\nREMOTE:", cmd)
        _, stdout, stderr = ssh.exec_command(cmd)
        code = stdout.channel.recv_exit_status()
        out = stdout.read().decode(errors="replace")
        err = stderr.read().decode(errors="replace")
        print("EXIT:", code)
        _safe_print_block("OUT", out)
        _safe_print_block("ERR", err)

    ssh.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

