"""Проверка окружения и исправление"""
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
    return code, safe_out[:8000], safe_err[:6000]

print("Checking environment and fixing...")

# Проверка версий
print("\n[1] Checking versions...")
code, node_version, _ = safe_run("node --version")
code, npm_version, _ = safe_run("npm --version")
code, next_version, _ = safe_run(f"cd {REMOTE_DIR} && npm list next 2>&1 | grep next")
print(f"Node: {node_version[:50]}")
print(f"npm: {npm_version[:50]}")
print(f"Next.js: {next_version[:100]}")

# Проверка памяти
code, memory, _ = safe_run("free -h")
print(f"\nMemory: {memory[:300]}")

# Запуск с максимальным логированием и обработкой ошибок
print("\n[2] Starting with maximum logging...")
start_script = f"""#!/bin/bash
cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
export DEBUG=*
export NODE_OPTIONS='--trace-warnings --unhandled-rejections=strict'

# Запуск с перенаправлением всех выводов
exec npm run dev -- -p 3000 -H 127.0.0.1 2>&1 | tee /tmp/nextjs-debug.log
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-debug.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-debug.sh", 0o755)
finally:
    sftp.close()

# Запуск в фоне
code, start_out, _ = safe_run("bash /tmp/start-debug.sh > /tmp/nextjs-background.log 2>&1 & echo $!")
print(f"Started with PID: {start_out[:50]}")

# Ждем
print("\n[3] Waiting 20 seconds...")
time.sleep(20)

# Проверка процесса
code, process_check, _ = safe_run("ps aux | grep -E 'next|node.*3000' | grep -v grep")
print("Processes:")
print(process_check[:1000])

# Проверка логов
code, debug_log, _ = safe_run("tail -200 /tmp/nextjs-debug.log 2>&1")
print("\nDebug log:")
print(debug_log[:6000])

code, background_log, _ = safe_run("tail -200 /tmp/nextjs-background.log 2>&1")
print("\nBackground log:")
print(background_log[:6000])

# Проверка порта
code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print(f"\nPort: {port_check[:400]}")

# Если порт слушается, тестируем
if "NOT_FOUND" not in port_check:
    print("\n[4] Port is listening! Testing...")
    code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=10)
    if response and len(response) > 50:
        print("[OK] Application is responding!")
        print(response[:700])
        
        # Запускаем через PM2
        print("\n[5] Starting via PM2...")
        safe_run("pkill -f 'next dev' || true")
        time.sleep(2)
        
        code, pm2_start, _ = safe_run("pm2 start /tmp/start-debug.sh --name deti-admin --interpreter bash")
        print(f"PM2 start: {pm2_start[:600]}")
        
        time.sleep(30)
        code, port_final, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
        if "NOT_FOUND" not in port_final:
            print("[OK] Application running via PM2!")
            safe_run("pm2 save")
        else:
            print("[WARN] Port not listening via PM2")

ssh.close()

print("\nDone!")
