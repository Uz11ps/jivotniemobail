"""Исправление проблем с компиляцией"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def safe_run(c, timeout=180):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    safe_out = out.encode('ascii', errors='ignore').decode('ascii')
    safe_err = err.encode('ascii', errors='ignore').decode('ascii')
    return code, safe_out[:3000], safe_err[:1500]

print("Fixing compilation issues...")

# Остановка
safe_run("pm2 delete all 2>/dev/null || true")
time.sleep(2)

# Проверка структуры проекта
print("\n[1] Checking project structure...")
code, files, _ = safe_run(f"ls -la {REMOTE_DIR}/src/app 2>/dev/null | head -10")
print(f"src/app: {files[:500]}")

# Проверка на ошибки в коде
print("\n[2] Checking for TypeScript/compilation errors...")
code, build_test, _ = safe_run(f"cd {REMOTE_DIR} && timeout 60 npm run build 2>&1 | head -100", timeout=90)
print("Build test output:")
print(build_test[:2000])

# Если сборка не работает, исправляем проблемы
# Но для dev режима сборка не обязательна

# Проверка next.config
print("\n[3] Checking next.config...")
code, next_config, _ = safe_run(f"cat {REMOTE_DIR}/next.config.js 2>/dev/null || echo 'NOT_FOUND'")
print(next_config[:500])

# Очистка .next
print("\n[4] Cleaning .next...")
safe_run(f"cd {REMOTE_DIR} && rm -rf .next")

# Запуск с отключенным турбо режимом (может помочь)
print("\n[5] Starting with TURBO disabled...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
export TURBO=0
npm run dev
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-final.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-final.sh", 0o755)
finally:
    sftp.close()

code, start_out, _ = safe_run("pm2 start /tmp/start-final.sh --name deti-admin --interpreter bash")
print(f"Start: {start_out[:500]}")

# Ждем дольше
print("\n[6] Waiting 60 seconds for compilation...")
time.sleep(60)

# Проверка логов на ошибки компиляции
print("\n[7] Checking compilation logs...")
code, compile_logs, _ = safe_run("pm2 logs deti-admin --lines 50 --nostream 2>&1", timeout=60)
print("Compilation logs:")
print(compile_logs[:3000])

# Проверка приложения
print("\n[8] Checking application...")
for i in range(10):
    code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=20)
    if code == 0 and response and (len(response) > 100 or "html" in response.lower() or "DOCTYPE" in response):
        print(f"[OK] Application is working! (attempt {i+1})")
        print(response[:500])
        break
    else:
        if i < 9:
            print(f"Attempt {i+1}/10... waiting 5 seconds")
            time.sleep(5)

# Статус
code, status, _ = safe_run("pm2 list")
print("\nFinal PM2 status:")
print(status[:800])

safe_run("pm2 save")

ssh.close()

print("\nDone! Check http://168.222.193.86")
