"""Просмотр реальных ошибок"""
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
    return code, safe_out[:10000], safe_err[:8000]

print("Seeing real errors...")

# Остановка PM2
safe_run("pm2 delete all 2>/dev/null || true")
safe_run("pkill -9 node 2>/dev/null || true")
time.sleep(2)

# Запуск напрямую с полным выводом
print("\n[1] Running directly to see errors...")
run_cmd = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
timeout 60 npm run dev -- -p 3000 -H 127.0.0.1 2>&1
"""
code, direct_output, direct_err = safe_run(run_cmd, timeout=70)
print("Direct output:")
print(direct_output[:8000])
if direct_err and len(direct_err) > 100:
    print("\nDirect errors:")
    print(direct_err[:6000])

# Если есть ошибки компиляции, проверяем файлы
if "error" in direct_output.lower() or "Error" in direct_output or "failed" in direct_output.lower():
    print("\n[2] Errors found, checking files...")
    
    # Проверка структуры
    code, file_structure, _ = safe_run(f"find {REMOTE_DIR}/src/app -type f | head -10")
    print(f"Files: {file_structure[:1000]}")
    
    # Проверка содержимого файлов
    code, layout_check, _ = safe_run(f"cat {REMOTE_DIR}/src/app/layout.tsx")
    print(f"\nLayout content: {layout_check[:500]}")
    
    code, page_check, _ = safe_run(f"cat {REMOTE_DIR}/src/app/page.tsx")
    print(f"\nPage content: {page_check[:500]}")

ssh.close()

print("\nDone!")
