"""Исправление проблемы с портом"""
import paramiko
import time
import sys

if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def cmd(c, timeout=60):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    return code, out

print("Fixing port issue...")

# 1. Остановка всех процессов
print("\n[1] Stopping all processes...")
cmd("pm2 delete all 2>/dev/null || true")
time.sleep(2)

# 2. Убиваем все процессы на портах 3000 и 3001
print("[2] Freeing ports 3000 and 3001...")
cmd("pkill -f 'node.*3000' || true")
cmd("pkill -f 'node.*3001' || true")
cmd("pkill -f 'next.*dev' || true")
cmd("pkill -f 'next.*start' || true")
time.sleep(2)

# 3. Проверка что порты свободны
print("[3] Checking ports...")
code, port_check = cmd("lsof -i :3000 2>/dev/null || ss -tlnp | grep ':3000' || echo 'FREE'")
if "FREE" not in port_check and "3000" in port_check:
    print("  Port 3000 still busy, forcing kill...")
    cmd("fuser -k 3000/tcp 2>/dev/null || true")
    time.sleep(2)

# 4. Запуск с явным указанием порта
print("[4] Starting application on port 3000...")
code, out = cmd(f"cd {REMOTE_DIR} && PORT=3000 pm2 start npm --name deti-admin -- run dev")
print(f"  Exit code: {code}")

# Альтернативный способ - через ecosystem файл
print("[5] Creating PM2 ecosystem config...")
ecosystem = """module.exports = {
  apps: [{
    name: 'deti-admin',
    script: 'npm',
    args: 'run dev',
    cwd: '/var/www/168-222-193-86.regru.cloud/data/www/deti-admin',
    env: {
      PORT: '3000',
      NODE_ENV: 'development'
    }
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

# Перезапуск через ecosystem
cmd("pm2 delete deti-admin 2>/dev/null || true")
time.sleep(2)
code, out = cmd(f"cd {REMOTE_DIR} && pm2 start ecosystem.config.js")
print(f"  Started via ecosystem, exit code: {code}")

print("[6] Waiting for startup (25 seconds)...")
time.sleep(25)

# Проверка
print("[7] Checking application...")
for i in range(5):
    code, out = cmd("curl -s http://127.0.0.1:3000 2>&1 | head -10")
    if code == 0 and (len(out) > 50 or "html" in out.lower() or "next" in out.lower()):
        print(f"  [OK] Application is working on port 3000! (attempt {i+1})")
        print(f"  Response: {out[:200]}")
        break
    else:
        print(f"  Attempt {i+1}/5...")
        time.sleep(5)

# Проверка портов
print("\n[8] Checking what's listening on ports...")
code, ports = cmd("ss -tlnp | grep -E ':(3000|3001)' || lsof -i :3000,3001 2>/dev/null || echo 'NO_INFO'")
print(ports[:500])

cmd("pm2 save")

ssh.close()

print("\n" + "="*60)
print("DONE!")
print("="*60)
print("Application should be running on port 3000")
print("Check: http://168.222.193.86")
print("\nIf still 502:")
print("  ssh root@168.222.193.86")
print("  pm2 logs deti-admin")
print("  pm2 restart deti-admin")
