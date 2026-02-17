"""Выполнение команд на сервере без проблем с выводом"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def run(c, timeout=120):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    return code, out[:2000] if len(out) > 2000 else out

print("Executing fix on server...")

# Загружаем скрипт
print("\n[1] Uploading fix script...")
script_content = """#!/bin/bash
pm2 delete all 2>/dev/null || true
pm2 kill 2>/dev/null || true
pkill -9 node 2>/dev/null || true
pkill -9 npm 2>/dev/null || true
pkill -9 next 2>/dev/null || true
sleep 3
fuser -k 3000/tcp 2>/dev/null || true
lsof -ti :3000 | xargs kill -9 2>/dev/null || true
sleep 3
cd /var/www/168-222-193-86.regru.cloud/data/www/deti-admin
PORT=3000 NODE_ENV=development pm2 start npm --name deti-admin -- run dev
pm2 save
sleep 30
curl -s http://127.0.0.1:3000 > /dev/null 2>&1 && echo "OK" || echo "FAIL"
pm2 list
"""

sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/fix.sh", "w") as f:
        f.write(script_content)
    sftp.chmod("/tmp/fix.sh", 0o755)
finally:
    sftp.close()

# Выполняем скрипт
print("[2] Running fix script...")
code, output = run("bash /tmp/fix.sh", timeout=180)
print("Output:")
# Безопасный вывод
safe_output = output.encode('ascii', errors='ignore').decode('ascii')
print(safe_output[:1500])

# Финальная проверка
print("\n[3] Final check...")
time.sleep(10)
code, check = run("curl -s http://127.0.0.1:3000 2>&1 | head -10")
if "html" in check.lower() or "next" in check.lower() or len(check) > 50:
    print("[OK] Application is responding!")
else:
    print("[WARN] Application may still be starting")

code, status = run("pm2 list")
print("\nPM2 Status:")
safe_status = status.encode('ascii', errors='ignore').decode('ascii')
print(safe_status[:600])

ssh.close()

print("\nDone! Check http://168.222.193.86")
