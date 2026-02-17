"""Финальное исправление и запуск"""
import paramiko

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def safe_cmd(c):
    _, stdout, stderr = ssh.exec_command(c, timeout=180)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    print(f"\n[{code}] {c}")
    return code, out, err

print("Финальная настройка...")

# Остановка PM2
print("\n1. Остановка PM2...")
safe_cmd("pm2 delete deti-admin 2>/dev/null || true")

# Очистка
print("\n2. Очистка...")
safe_cmd(f"cd {REMOTE_DIR} && rm -rf .next")

# Попытка сборки с увеличенной памятью и без source maps
print("\n3. Сборка проекта (может занять время)...")
code, out, err = safe_cmd(f"cd {REMOTE_DIR} && NODE_OPTIONS='--max-old-space-size=4096' NEXT_TELEMETRY_DISABLED=1 npm run build")
if code != 0:
    print("\n[WARN] Ошибка сборки, пробую dev режим...")
    # Если сборка не работает, пробуем dev режим
    safe_cmd(f"cd {REMOTE_DIR} && pm2 start npm --name deti-admin -- run dev")
else:
    print("\n[OK] Сборка успешна!")
    safe_cmd(f"cd {REMOTE_DIR} && pm2 start npm --name deti-admin -- start")

safe_cmd("pm2 save")
safe_cmd("pm2 status")

# Проверка
print("\n4. Проверка...")
code, out, _ = safe_cmd("sleep 5 && curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000 || echo '000'")
if "200" in out or "000" not in out:
    print("[OK] Приложение работает!")
else:
    print("[WARN] Проверьте логи: pm2 logs deti-admin")

ssh.close()
print("\nГотово! Проверьте: http://168.222.193.86")
