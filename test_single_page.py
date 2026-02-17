"""Тест с одной страницей"""
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
    return code, safe_out[:6000], safe_err[:4000]

print("Testing with single page...")

# Остановка
safe_run("pm2 delete all 2>/dev/null || true")
time.sleep(2)

# Временное переименование других страниц
print("\n[1] Temporarily moving other pages...")
safe_run(f"cd {REMOTE_DIR}/src/app && mkdir -p ../app_backup")
safe_run(f"cd {REMOTE_DIR}/src/app && mv login dashboard offers analytics categories users ../app_backup/ 2>/dev/null || true")

# Оставляем только layout.tsx, page.tsx и globals.css
code, remaining_files, _ = safe_run(f"ls -la {REMOTE_DIR}/src/app/")
print(f"Remaining files: {remaining_files[:800]}")

# Очистка
print("\n[2] Cleaning...")
safe_run(f"cd {REMOTE_DIR} && rm -rf .next")

# Запуск
print("[3] Starting...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
exec npm run dev -- -p 3000 -H 127.0.0.1
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-single.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-single.sh", 0o755)
finally:
    sftp.close()

code, start_out, _ = safe_run("pm2 start /tmp/start-single.sh --name deti-admin --interpreter bash")
print(f"Start: {start_out[:600]}")

# Ждем
print("\n[4] Waiting 90 seconds...")
time.sleep(90)

# Проверка
print("[5] Checking application...")
code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print(f"Port: {port_check[:400]}")

if "NOT_FOUND" not in port_check:
    print("[OK] Port is listening!")
    code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=10)
    if response and len(response) > 50:
        print(f"[OK] Application is responding!")
        print(response[:700])
        
        # Возвращаем страницы обратно
        print("\n[6] Restoring other pages...")
        safe_run(f"cd {REMOTE_DIR}/src && mv app_backup/* app/ 2>/dev/null && rmdir app_backup 2>/dev/null || true")
        print("Pages restored")
    else:
        print("No response")
else:
    print("[WARN] Port not listening")
    code, logs, _ = safe_run("pm2 logs deti-admin --lines 100 --nostream 2>&1", timeout=60)
    print("Logs:")
    print(logs[:5000])
    
    # Возвращаем страницы
    safe_run(f"cd {REMOTE_DIR}/src && mv app_backup/* app/ 2>/dev/null && rmdir app_backup 2>/dev/null || true")

code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\nDone!")
