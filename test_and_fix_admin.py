"""Тестирование и исправление админ панели"""
import paramiko

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def safe_run(c, timeout=60):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    safe_out = out.encode('ascii', errors='ignore').decode('ascii')
    safe_err = err.encode('ascii', errors='ignore').decode('ascii')
    return code, safe_out[:10000], safe_err[:8000]

print("Testing admin panel...")

# Проверка порта
code, port, _ = safe_run("ss -tlnp | grep :3000")
print(f"Port: {port[:300]}")

# Тест страниц
pages = ['/', '/categories', '/dashboard', '/offers', '/analytics']
for page in pages:
    code, response, _ = safe_run(f"curl -s http://127.0.0.1:3000{page} 2>&1 | head -50", timeout=10)
    if response and len(response) > 100:
        print(f"[OK] {page} - working")
    else:
        print(f"[ERROR] {page} - not working")
        print(response[:500])

# Проверка логов на ошибки
code, logs, _ = safe_run("pm2 logs deti-admin --lines 30 --nostream 2>&1", timeout=60)
if "error" in logs.lower() or "Error" in logs:
    print("\nErrors in logs:")
    print(logs[:3000])

ssh.close()

print("\nDone!")
