"""Финальное исправление структуры"""
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

print("Final structure fix...")

# Остановка
safe_run("pm2 delete all 2>/dev/null || true")
time.sleep(2)

# Проверка структуры
print("\n[1] Checking file structure...")
code, files, _ = safe_run(f"find {REMOTE_DIR}/src/app -name '*.tsx' -o -name '*.ts' | head -20")
print(f"Files found: {files[:1000]}")

# Проверка что файлы читаемы
print("\n[2] Checking file permissions...")
code, perms, _ = safe_run(f"ls -la {REMOTE_DIR}/src/app/page.tsx {REMOTE_DIR}/src/app/layout.tsx")
print(perms[:500])

# Проверка next.config
print("\n[3] Checking next.config.js...")
code, next_cfg, _ = safe_run(f"cat {REMOTE_DIR}/next.config.js")
print(next_cfg[:500])

# Обновление next.config для явного указания src директории
print("\n[4] Updating next.config.js...")
new_next_config = """/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    domains: ['firebasestorage.googleapis.com'],
  },
  // Явно указываем что используем src директорию
  distDir: '.next',
  // Отключаем оптимизации для dev режима
  swcMinify: false,
}
module.exports = nextConfig
"""
sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/next.config.js", "w") as f:
        f.write(new_next_config)
    print("  next.config.js updated")
except Exception as e:
    print(f"  Error: {e}")
finally:
    sftp.close()

# Полная очистка
print("\n[5] Complete cleanup...")
safe_run(f"cd {REMOTE_DIR} && rm -rf .next node_modules/.cache")

# Запуск
print("\n[6] Starting application...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
# Явно указываем что используем src
export NEXT_PRIVATE_STANDALONE=false
npm run dev
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-app-final.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-app-final.sh", 0o755)
finally:
    sftp.close()

code, start_out, _ = safe_run("pm2 start /tmp/start-app-final.sh --name deti-admin --interpreter bash")
print(f"Start: {start_out[:500]}")

# Ждем дольше для компиляции
print("\n[7] Waiting 90 seconds for full compilation...")
time.sleep(90)

# Проверка
print("\n[8] Checking application...")
for i in range(15):
    code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=20)
    if code == 0 and response and (len(response) > 100 or "html" in response.lower() or "DOCTYPE" in response or "next" in response.lower() or "script" in response.lower()):
        print(f"[OK] Application is working! (attempt {i+1})")
        print(response[:700])
        break
    else:
        if i < 14:
            print(f"Attempt {i+1}/15... waiting 5 seconds")
            time.sleep(5)

# Проверка логов на ошибки компиляции
print("\n[9] Checking compilation errors...")
code, err_logs, _ = safe_run("pm2 logs deti-admin --err --lines 50 --nostream 2>&1", timeout=60)
if err_logs and len(err_logs) > 100:
    print("Error logs found:")
    print(err_logs[:2500])

# Статус
code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:800])

safe_run("pm2 save")

ssh.close()

print("\n" + "="*60)
print("COMPLETE!")
print("="*60)
print("If still not working, check:")
print("  ssh root@168.222.193.86")
print("  pm2 logs deti-admin --lines 100")
print("  ls -la /var/www/168-222-193-86.regru.cloud/data/www/deti-admin/src/app/")
