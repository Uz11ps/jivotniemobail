"""Тест с запросом"""
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
    return code, safe_out[:10000], safe_err[:8000]

print("Testing with request...")

# Остановка
safe_run("pm2 delete all 2>/dev/null || true")
safe_run("pkill -9 node 2>/dev/null || true")
time.sleep(2)

# Запуск в фоне с логированием
print("\n[1] Starting in background with logging...")
start_cmd = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
nohup npm run dev -- -p 3000 -H 127.0.0.1 > /tmp/nextjs-bg.log 2>&1 &
echo $! > /tmp/nextjs.pid
sleep 15
"""
code, start_out, _ = safe_run(start_cmd)
print(f"Started: {start_out[:500]}")

# Проверка процесса
code, pid_check, _ = safe_run("ps -p $(cat /tmp/nextjs.pid 2>/dev/null) 2>/dev/null || echo 'NOT_RUNNING'")
print(f"Process check: {pid_check[:300]}")

# Проверка порта
code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print(f"Port: {port_check[:400]}")

# Проверка логов
code, logs, _ = safe_run("tail -100 /tmp/nextjs-bg.log 2>&1")
print("\nBackground logs:")
print(logs[:6000])

# Если порт слушается, делаем запрос
if "NOT_FOUND" not in port_check:
    print("\n[2] Port is listening, making request...")
    code, response, _ = safe_run("curl -v http://127.0.0.1:3000 2>&1", timeout=15)
    print("Response:")
    print(response[:4000])
    
    # Проверка логов после запроса
    time.sleep(2)
    code, logs_after, _ = safe_run("tail -50 /tmp/nextjs-bg.log 2>&1")
    print("\nLogs after request:")
    print(logs_after[:4000])
    
    # Если работает, запускаем через PM2
    if response and len(response) > 50 and "502" not in response:
        print("\n[3] Application works! Starting via PM2...")
        safe_run("kill $(cat /tmp/nextjs.pid 2>/dev/null) 2>/dev/null || true")
        time.sleep(2)
        
        start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
exec npm run dev -- -p 3000 -H 127.0.0.1
"""
        sftp = ssh.open_sftp()
        try:
            with sftp.open("/tmp/start-pm2.sh", "w") as f:
                f.write(start_script)
            sftp.chmod("/tmp/start-pm2.sh", 0o755)
        finally:
            sftp.close()
        
        code, pm2_start, _ = safe_run("pm2 start /tmp/start-pm2.sh --name deti-admin --interpreter bash")
        print(f"PM2 start: {pm2_start[:600]}")
        
        time.sleep(30)
        code, final_test, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=10)
        if final_test and len(final_test) > 20:
            print("[OK] Application running via PM2!")
            safe_run("pm2 save")
        else:
            print("Still not responding via PM2")

ssh.close()

print("\nDone!")
