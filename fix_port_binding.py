"""Исправление привязки к порту"""
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

print("Fixing port binding...")

# Полная остановка
print("\n[1] Complete stop...")
safe_run("pm2 delete all 2>/dev/null || true")
safe_run("pkill -9 node 2>/dev/null || true")
safe_run("pkill -9 npm 2>/dev/null || true")
time.sleep(3)

# Освобождение порта
safe_run("fuser -k 3000/tcp 2>/dev/null || true")
safe_run("lsof -ti :3000 | xargs kill -9 2>/dev/null || true")
time.sleep(2)

# Проверка что порт свободен
code, port_check, _ = safe_run("lsof -i :3000 2>/dev/null || echo 'FREE'")
if "FREE" not in port_check:
    print("Port still busy!")
    safe_run("ss -K dst :3000 2>/dev/null || true")
    time.sleep(2)

# Обновление next.config - убираем swcMinify
print("\n[2] Updating next.config.js...")
new_config = """/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    domains: ['firebasestorage.googleapis.com'],
  },
}
module.exports = nextConfig
"""
sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/next.config.js", "w") as f:
        f.write(new_config)
finally:
    sftp.close()

# Создание правильного скрипта запуска с явным указанием хоста
print("\n[3] Creating start script...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
exec npm run dev -- -p 3000 -H 127.0.0.1
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-port.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-port.sh", 0o755)
finally:
    sftp.close()

# Запуск
print("[4] Starting application...")
code, start_out, _ = safe_run("pm2 start /tmp/start-port.sh --name deti-admin --interpreter bash")
print(f"Start: {start_out[:500]}")

# Ждем
print("\n[5] Waiting 60 seconds...")
time.sleep(60)

# Проверка портов
print("\n[6] Checking ports...")
code, ports, _ = safe_run("netstat -tlnp 2>/dev/null | grep :3000 || ss -tlnp | grep :3000 || lsof -i :3000 || echo 'NOT_FOUND'")
print(f"Port 3000: {ports[:500]}")

# Проверка процессов
code, procs, _ = safe_run("ps aux | grep -E 'next|node.*3000' | grep -v grep | head -5")
print(f"\nProcesses: {procs[:500]}")

# Проверка приложения
print("\n[7] Testing application...")
for i in range(10):
    code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=15)
    if code == 0 and response and (len(response) > 50 or "html" in response.lower() or "DOCTYPE" in response):
        print(f"[OK] Application is working! (attempt {i+1})")
        print(response[:500])
        break
    else:
        if i < 9:
            print(f"Attempt {i+1}/10... waiting 5 seconds")
            time.sleep(5)

# Логи
print("\n[8] Recent logs...")
code, logs, _ = safe_run("pm2 logs deti-admin --lines 20 --nostream 2>&1", timeout=60)
print(logs[:2000])

# Статус
code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\nDone!")
