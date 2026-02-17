"""Полное исправление и деплой"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def run(c, timeout=60):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    return code, out, err

print("Complete fix and deploy...")

# 1. Полная остановка
print("\n[1] Complete stop...")
run("pm2 delete all 2>/dev/null || true")
run("pm2 kill 2>/dev/null || true")
time.sleep(3)

# 2. Убиваем ВСЕ процессы связанные с node/next
print("[2] Killing all node/next processes...")
run("pkill -9 node || true")
run("pkill -9 npm || true")
run("pkill -9 next || true")
time.sleep(3)

# 3. Освобождаем порт 3000 агрессивно
print("[3] Freeing port 3000...")
run("fuser -k 3000/tcp 2>/dev/null || true")
run("lsof -ti :3000 | xargs kill -9 2>/dev/null || true")
run("ss -K dst :3000 2>/dev/null || true")
time.sleep(3)

# 4. Проверка что порт свободен
print("[4] Verifying port is free...")
code, check, _ = run("lsof -i :3000 2>/dev/null || ss -tlnp | grep :3000 || echo 'FREE'")
if "FREE" not in check:
    print("  Port still busy, trying more aggressive cleanup...")
    run("netstat -tlnp | grep :3000 | awk '{print $7}' | cut -d'/' -f1 | xargs kill -9 2>/dev/null || true")
    time.sleep(2)

# 5. Создаем правильный ecosystem файл
print("[5] Creating PM2 ecosystem config...")
ecosystem = """module.exports = {
  apps: [{
    name: 'deti-admin',
    script: 'npm',
    args: 'run dev',
    cwd: '/var/www/168-222-193-86.regru.cloud/data/www/deti-admin',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'development',
      PORT: '3000'
    },
    error_file: '/root/.pm2/logs/deti-admin-error.log',
    out_file: '/root/.pm2/logs/deti-admin-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
"""
sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/ecosystem.config.js", "w") as f:
        f.write(ecosystem)
    print("  Ecosystem config created")
except Exception as e:
    print(f"  Error creating config: {e}")
finally:
    sftp.close()

# 6. Запуск через ecosystem
print("[6] Starting via ecosystem...")
code, out, err = run(f"cd {REMOTE_DIR} && pm2 start ecosystem.config.js")
print(f"  Exit code: {code}")
if err:
    print(f"  Error: {err[:300]}")

# 7. Ждем достаточно времени
print("[7] Waiting for startup (40 seconds)...")
time.sleep(40)

# 8. Проверка
print("[8] Checking application...")
for i in range(10):
    code, response, _ = run("curl -s http://127.0.0.1:3000 2>&1 | head -10", timeout=10)
    if code == 0 and (len(response) > 50 or "html" in response.lower() or "next" in response.lower() or "DOCTYPE" in response):
        print(f"  [OK] Application is working! (attempt {i+1})")
        print(f"  Response: {response[:300]}")
        break
    else:
        if i < 9:
            print(f"  Attempt {i+1}/10... waiting 5 seconds")
            time.sleep(5)
        else:
            print("  [WARN] Application may still be starting")

# 9. PM2 статус и логи
print("\n[9] PM2 status and recent logs...")
code, status, _ = run("pm2 list")
print("Status:")
# Безопасный вывод
try:
    safe_status = status.encode('ascii', errors='ignore').decode('ascii')
    print(safe_status[:800])
except:
    print("(status output contains special characters)")

code, logs, _ = run("pm2 logs deti-admin --lines 5 --nostream 2>&1", timeout=30)
print("\nRecent logs:")
try:
    safe_logs = logs.encode('ascii', errors='ignore').decode('ascii')
    print(safe_logs[:1000])
except:
    print("(logs contain special characters)")

# 10. Сохранение
run("pm2 save")

# 11. Финальная проверка через nginx
print("\n[10] Final check through nginx...")
time.sleep(5)
code, nginx, _ = run("curl -s -I http://127.0.0.1/ 2>&1 | head -5")
print(nginx[:400])

ssh.close()

print("\n" + "="*60)
print("COMPLETE!")
print("="*60)
print("Application should be running")
print("Check: http://168.222.193.86")
print("\nIf still issues:")
print("  ssh root@168.222.193.86")
print("  pm2 logs deti-admin --lines 50")
print("  lsof -i :3000")
print("  pm2 restart deti-admin")
