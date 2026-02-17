"""Исправление конфликта портов и режима запуска"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def run(c):
    _, stdout, stderr = ssh.exec_command(c, timeout=60)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    return code, out, err

print("Fixing port conflict and startup mode...")

# 1. Остановка PM2
print("\n[1] Stopping PM2...")
run("pm2 delete all")
time.sleep(3)

# 2. Находим и убиваем все процессы на порту 3000
print("[2] Finding processes on port 3000...")
code, out, _ = run("lsof -ti :3000 || fuser 3000/tcp 2>/dev/null || ss -tlnp | grep :3000 | awk '{print $7}' | cut -d',' -f2 | cut -d'=' -f2 | sort -u")
if out.strip():
    print(f"  Found processes: {out[:200]}")
    # Убиваем процессы
    pids = [p for p in out.strip().split('\n') if p.isdigit()]
    for pid in pids:
        run(f"kill -9 {pid} 2>/dev/null || true")
    run("pkill -9 -f 'node.*3000' || true")
    run("pkill -9 -f 'next.*3000' || true")
    time.sleep(2)

# 3. Дополнительная очистка
print("[3] Additional cleanup...")
run("pkill -9 -f 'next dev' || true")
run("pkill -9 -f 'next start' || true")
run("pkill -9 -f 'npm.*dev' || true")
time.sleep(2)

# 4. Проверка что порт свободен
print("[4] Verifying port 3000 is free...")
code, check, _ = run("lsof -i :3000 2>/dev/null || echo 'FREE'")
if "FREE" not in check:
    print("  Port still busy, using fuser...")
    run("fuser -k 3000/tcp 2>/dev/null || true")
    time.sleep(2)

# 5. Запуск в dev режиме с явным портом
print("[5] Starting in dev mode on port 3000...")
# Создаем скрипт запуска
start_script = f"""#!/bin/bash
cd {REMOTE_DIR}
export PORT=3000
npm run dev
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-dev.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-dev.sh", 0o755)
finally:
    sftp.close()

# Запускаем через PM2 с правильной командой
code, out, err = run(f"pm2 start /tmp/start-dev.sh --name deti-admin --interpreter bash")
print(f"  Exit code: {code}")
if err:
    print(f"  Error: {err[:300]}")

# Ждем запуска
print("[6] Waiting for startup (30 seconds)...")
time.sleep(30)

# Проверка
print("[7] Checking application...")
for i in range(5):
    code, response, _ = run("curl -s http://127.0.0.1:3000 2>&1 | head -10")
    if code == 0 and (len(response) > 50 or "html" in response.lower() or "next" in response.lower()):
        print(f"  [OK] Application is working! (attempt {i+1})")
        print(f"  Response preview: {response[:200]}")
        break
    else:
        print(f"  Attempt {i+1}/5... waiting 5 seconds")
        time.sleep(5)

# PM2 статус
print("\n[8] PM2 status...")
code, status, _ = run("pm2 list")
print(status[:600])

# Сохранение
run("pm2 save")

ssh.close()

print("\n" + "="*60)
print("DONE!")
print("="*60)
print("Application should be running on port 3000")
print("Check: http://168.222.193.86")
print("\nIf still issues:")
print("  ssh root@168.222.193.86")
print("  pm2 logs deti-admin --lines 30")
print("  pm2 restart deti-admin")
