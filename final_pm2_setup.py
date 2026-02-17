"""Финальная настройка PM2"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def safe_run(c, timeout=120):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    safe_out = out.encode('ascii', errors='ignore').decode('ascii')
    safe_err = err.encode('ascii', errors='ignore').decode('ascii')
    return code, safe_out[:3000], safe_err[:1500]

print("Final PM2 setup...")

# Остановка
safe_run("pm2 delete all 2>/dev/null || true")
time.sleep(2)

# Создание правильного ecosystem файла
print("\n[1] Creating PM2 ecosystem config...")
ecosystem = """module.exports = {
  apps: [{
    name: 'deti-admin',
    script: 'node_modules/.bin/next',
    args: 'dev -p 3000 -H 127.0.0.1',
    cwd: '/var/www/168-222-193-86.regru.cloud/data/www/deti-admin',
    instances: 1,
    exec_mode: 'fork',
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'development',
      PORT: '3000',
      HOSTNAME: '127.0.0.1',
      NEXT_TELEMETRY_DISABLED: '1'
    },
    error_file: '/root/.pm2/logs/deti-admin-error.log',
    out_file: '/root/.pm2/logs/deti-admin-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    kill_timeout: 5000,
    wait_ready: true,
    listen_timeout: 10000
  }]
};
"""
sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/ecosystem.config.js", "w") as f:
        f.write(ecosystem)
    print("  Ecosystem config created")
except Exception as e:
    print(f"  Error: {e}")
finally:
    sftp.close()

# Запуск через ecosystem
print("\n[2] Starting via ecosystem...")
code, start_out, _ = safe_run(f"cd {REMOTE_DIR} && pm2 start ecosystem.config.js")
print(f"Start: {start_out[:600]}")

# Ждем
print("\n[3] Waiting 90 seconds for startup and compilation...")
time.sleep(90)

# Проверка
print("\n[4] Checking application...")
for i in range(20):
    code, response, _ = safe_run("curl -s -m 10 http://127.0.0.1:3000 2>&1", timeout=15)
    if code == 0 and response and (len(response) > 100 or "html" in response.lower() or "DOCTYPE" in response or "script" in response.lower()):
        print(f"[OK] Application is working! (attempt {i+1})")
        print(f"Response length: {len(response)}")
        print(response[:700])
        break
    else:
        if i < 19:
            print(f"Attempt {i+1}/20... waiting 5 seconds")
            time.sleep(5)

# Проверка порта
code, port, _ = safe_run("ss -tlnp | grep :3000")
print(f"\nPort status: {port[:300]}")

# Статус
code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:800])

# Логи
code, logs, _ = safe_run("pm2 logs deti-admin --lines 15 --nostream 2>&1", timeout=60)
print("\nRecent logs:")
print(logs[:2000])

safe_run("pm2 save")

ssh.close()

print("\n" + "="*60)
print("DEPLOYMENT COMPLETE!")
print("="*60)
print("Application should be accessible at: http://168.222.193.86")
print("\nIf 502, wait 2-3 minutes for full compilation")
print("Monitor: pm2 logs deti-admin --lines 50")
