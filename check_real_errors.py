"""Проверка реальных ошибок"""
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
    return code, safe_out[:5000], safe_err[:3000]

print("Checking real compilation errors...")

# Остановка PM2
safe_run("pm2 delete all 2>/dev/null || true")
time.sleep(2)

# Запуск напрямую для просмотра ошибок
print("\n[1] Starting directly to see errors...")
code, direct_out, direct_err = safe_run(f"cd {REMOTE_DIR} && timeout 60 npm run dev 2>&1", timeout=70)
print("Direct start output:")
print(direct_out[:4000])
if direct_err:
    print("\nDirect start errors:")
    print(direct_err[:3000])

# Если есть ошибки компиляции, они будут видны здесь
# Проверяем на наличие ошибок импорта или компиляции
if "error" in direct_out.lower() or "Error" in direct_out or "failed" in direct_out.lower():
    print("\n[2] Found errors! Checking specific issues...")
    
    # Проверка зависимостей
    code, deps, _ = safe_run(f"cd {REMOTE_DIR} && npm list --depth=0 2>&1 | head -30")
    print("Dependencies:")
    print(deps[:1500])

ssh.close()

print("\nDone!")
