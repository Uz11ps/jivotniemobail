"""
Деплой админки (admin/) на сервер по SSH.

Требования:
  pip install paramiko scp

Переменные окружения (рекомендуется):
  DEPLOY_HOST       (по умолчанию 168.222.193.86)
  DEPLOY_PORT       (по умолчанию 22)
  DEPLOY_USER       (по умолчанию root)
  DEPLOY_PASSWORD   (обязательно, если нет ключа)
  DEPLOY_REMOTE_DIR (по умолчанию /root/deti-admin)

Что делает:
  1) Упаковывает содержимое папки admin/ в deti-admin.tgz (без node_modules/.next/.env)
  2) Загружает архив на сервер в /tmp
  3) Делает backup текущего /root/deti-admin -> /root/deti-admin_backup_YYYYmmdd_HHMMSS
  4) Разворачивает новый релиз
  5) npm ci / npm install, npm run build
  6) pm2 startOrRestart ecosystem.config.js (или fallback)
"""

from __future__ import annotations

import os
import sys
import time
import subprocess
from pathlib import Path

try:
    import paramiko
    from scp import SCPClient
except ImportError:
    print("Установите зависимости: pip install paramiko scp")
    raise
from paramiko.ssh_exception import SSHException


SERVER = os.getenv("DEPLOY_HOST", "168.222.193.86")
PORT = int(os.getenv("DEPLOY_PORT", "22"))
USER = os.getenv("DEPLOY_USER", "root")
PASSWORD = os.getenv("DEPLOY_PASSWORD", "")
REMOTE_DIR = os.getenv("DEPLOY_REMOTE_DIR", "/root/deti-admin")


def _run_local(cmd: list[str], cwd: Path) -> None:
    print("LOCAL:", " ".join(cmd))
    subprocess.check_call(cmd, cwd=str(cwd))


def _tar_admin(repo_root: Path) -> Path:
    admin_dir = repo_root / "admin"
    if not admin_dir.exists():
        raise RuntimeError(f"Не найдена папка admin/: {admin_dir}")

    # Собираем локально, чтобы не падать по OOM на сервере (exit 137).
    npm_exe = "npm.cmd" if os.name == "nt" else "npm"
    _run_local([npm_exe, "run", "build"], cwd=admin_dir)

    tar_path = repo_root / "deti-admin.tgz"
    if tar_path.exists():
        tar_path.unlink()

    # Упаковываем содержимое admin/ (не саму папку admin).
    cmd = [
        "tar",
        "-czf",
        str(tar_path),
        "--exclude=node_modules",
        # .next включаем (build делаем локально)
        "--exclude=.next/cache",
        "--exclude=.turbo",
        "--exclude=.env",
        "--exclude=.env.local",
        "--exclude=.env.production",
        "-C",
        str(admin_dir),
        ".",
    ]
    _run_local(cmd, cwd=repo_root)
    return tar_path


def deploy() -> None:
    # Windows консоль часто в cp1251: не печатаем emoji/юникод.
    repo_root = Path(__file__).resolve().parent
    tar_path = _tar_admin(repo_root)

    if not PASSWORD:
        print("DEPLOY_PASSWORD is not set. Provide it via environment variable.")
        print("Example (PowerShell):")
        print('  $env:DEPLOY_PASSWORD="***"; python .\\deploy_admin.py')
        sys.exit(2)

    print(f"Подключение к {SERVER}:{PORT} ...")
    last_err: Exception | None = None
    ssh: paramiko.SSHClient | None = None
    for attempt in range(1, 9):
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            client.connect(
                SERVER,
                PORT,
                USER,
                PASSWORD,
                timeout=30,
                banner_timeout=120,
                auth_timeout=120,
                look_for_keys=False,
                allow_agent=False,
            )
            transport = client.get_transport()
            if transport is not None:
                transport.set_keepalive(30)
            ssh = client
            last_err = None
            break
        except (SSHException, TimeoutError, OSError) as e:
            last_err = e
            try:
                client.close()
            except Exception:
                pass
            print(f"SSH connect failed (attempt {attempt}/8): {e}")
            time.sleep(2 + attempt)
    if ssh is None:
        raise last_err or RuntimeError("SSH connect failed")

    def run(cmd: str, check: bool = True) -> tuple[int, str, str]:
        print("REMOTE:", cmd)
        _, stdout, stderr = ssh.exec_command(cmd)
        code = stdout.channel.recv_exit_status()
        out = stdout.read().decode(errors="replace")
        err = stderr.read().decode(errors="replace")
        if check and code != 0:
            raise RuntimeError(f"Ошибка [{code}]: {cmd}\n{err or out}")
        return code, out, err

    # upload
    remote_archive = "/tmp/deti-admin.tgz"
    print("Загрузка архива на сервер...")
    with SCPClient(ssh.get_transport()) as scp:
        scp.put(str(tar_path), remote_archive)

    ts = time.strftime("%Y%m%d_%H%M%S")
    backup_dir = f"{REMOTE_DIR}_backup_{ts}"
    stage_dir = f"/tmp/deti-admin_stage_{ts}"

    run(f"set -e; rm -rf {stage_dir} && mkdir -p {stage_dir}")
    run(f"tar -xzf {remote_archive} -C {stage_dir}")

    # backup current
    run(f"set -e; if [ -d {REMOTE_DIR} ]; then mv {REMOTE_DIR} {backup_dir}; fi", check=True)
    run(f"mv {stage_dir} {REMOTE_DIR}")

    # restore env files if exist
    run(
        f"set -e; "
        f"if [ -d {backup_dir} ]; then "
        f"  if [ -f {backup_dir}/.env.production ]; then cp {backup_dir}/.env.production {REMOTE_DIR}/.env.production; fi; "
        f"  if [ -f {backup_dir}/.env.local ]; then cp {backup_dir}/.env.local {REMOTE_DIR}/.env.local; fi; "
        f"fi",
        check=True,
    )

    # deps + build
    # На сервере npm ci часто убивается по памяти, поэтому:
    # 1) берем node_modules из backup релиза (если есть)
    # 2) запускаем npm run build
    run(f"cd {REMOTE_DIR} && node -v && npm -v", check=True)
    run(
        f"set -e; "
        f"GOOD_BACKUP=$(ls -dt {REMOTE_DIR}_backup_* 2>/dev/null | "
        f"  while read d; do "
        f"    if [ -e \"$d/node_modules/.bin/next\" ]; then echo $d; break; fi; "
        f"  done || true); "
        f"if [ -n \"$GOOD_BACKUP\" ]; then "
        f"  echo \"Using node_modules from: $GOOD_BACKUP\"; "
        f"  rm -rf {REMOTE_DIR}/node_modules; "
        f"  mkdir -p {REMOTE_DIR}/node_modules; "
        f"  cp -a \"$GOOD_BACKUP/node_modules/.\" {REMOTE_DIR}/node_modules/; "
        f"else "
        f"  echo \"No good backup with next found; node_modules reuse skipped\"; "
        f"fi",
        check=True,
    )

    # Обновление/доустановка мелких зависимостей (busboy нужен для /api/upload).
    # Делаем точечно, чтобы не запускать npm ci/install на весь проект (часто OOM).
    run(
        f"set -e; cd {REMOTE_DIR}; "
        f"node -e \"require.resolve('busboy')\" >/dev/null 2>&1 || "
        f"npm install --omit=dev --no-audit --no-fund busboy",
        check=True,
    )

    # Директория для файлов, которые загружаются из админки на сервер.
    run("set -e; mkdir -p /var/www/deti-admin/uploads && chmod 755 /var/www/deti-admin/uploads", check=True)
    # build на сервере НЕ запускаем (сервер слабый, часто OOM).
    # В tar уже лежит .next после локального next build.

    # Синхронизация каталога в Firestore через Admin SDK сервера.
    code, _, _ = run(f"test -f {REMOTE_DIR}/scripts/sync_catalog.mjs", check=False)
    if code == 0:
        code, out, err = run(f"cd {REMOTE_DIR} && node scripts/sync_catalog.mjs", check=False)
        if code != 0:
            print("Admin SDK sync unavailable, trying Web SDK fallback...")
            print((err or out).strip())
            code2, out2, err2 = run(f"cd {REMOTE_DIR} && node scripts/seed_firestore.mjs", check=False)
            if code2 != 0:
                print("Catalog sync skipped: both Admin SDK and Web SDK writes are unavailable.")
                print((err2 or out2).strip())

    # restart
    run("command -v pm2 >/dev/null 2>&1", check=True)
    code, _, _ = run(f"test -f {REMOTE_DIR}/ecosystem.config.js", check=False)
    if code == 0:
        run(f"cd {REMOTE_DIR} && pm2 startOrRestart ecosystem.config.js", check=True)
    else:
        run(f"cd {REMOTE_DIR} && pm2 start npm --name deti-admin -- start", check=True)
    run("pm2 save || true", check=False)
    run("pm2 status || true", check=False)

    ssh.close()
    print("\nDEPLOY OK. Открой админку и проверь новые поля (цена/видео/аудио).")


if __name__ == "__main__":
    deploy()
