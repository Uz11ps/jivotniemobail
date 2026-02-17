"""Проверка интеграции Firebase"""
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

print("Verifying Firebase integration...")

# Проверка .env.local
print("\n[1] Checking .env.local...")
code, env_content, _ = safe_run(f"cat {REMOTE_DIR}/.env.local 2>&1")
print("Environment variables:")
for line in env_content.split('\n'):
    if 'FIREBASE' in line and '=' in line:
        key = line.split('=')[0].strip()
        value = line.split('=')[1].strip()[:50] if len(line.split('=')) > 1 else ''
        print(f"  {key}: {value[:50]}...")

# Тест API endpoints
print("\n[2] Testing API endpoints...")

# Тест получения категорий
code, api_response, _ = safe_run("curl -s http://127.0.0.1:3000/api/categories 2>&1", timeout=10)
if api_response:
    if "error" in api_response.lower():
        print(f"API error: {api_response[:500]}")
    else:
        print(f"[OK] API responding: {api_response[:200]}")

# Проверка что сервер использует правильный файл
code, server_check, _ = safe_run(f"head -20 {REMOTE_DIR}/server.js 2>&1")
if "Full admin panel" in server_check or "express" in server_check.lower():
    print("\n[OK] Correct server.js is being used")
else:
    print("\n[WARN] Server.js may not be correct")

# Проверка через браузер (Nginx)
code, nginx_test, _ = safe_run("curl -s http://127.0.0.1/categories 2>&1 | grep -E 'Категории|categories|table|Добавить' | head -5", timeout=10)
if nginx_test:
    print(f"\n[OK] Accessible through Nginx: {nginx_test[:300]}")

ssh.close()

print("\nDone! Admin panel should be fully functional now.")
print("Check: http://168.222.193.86/categories")
