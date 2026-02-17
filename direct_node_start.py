"""Запуск напрямую через node"""
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

print("Starting directly via node...")

# Остановка всего
safe_run("pm2 delete all 2>/dev/null || true")
safe_run("pkill -9 node 2>/dev/null || true")
safe_run("pkill -9 npm 2>/dev/null || true")
time.sleep(3)

# Освобождение порта
safe_run("fuser -k 3000/tcp 2>/dev/null || true")
safe_run("lsof -ti :3000 | xargs kill -9 2>/dev/null || true")
time.sleep(2)

# Запуск через nohup напрямую
print("\n[1] Starting via nohup...")
start_cmd = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
nohup npm run dev -- -p 3000 -H 127.0.0.1 > /tmp/nextjs-nohup.log 2>&1 &
echo $! > /tmp/nextjs.pid
"""
code, start_out, _ = safe_run(start_cmd)
print(f"Start output: {start_out[:500]}")

# Ждем
print("\n[2] Waiting 30 seconds...")
time.sleep(30)

# Проверка процесса
code, pid_check, _ = safe_run("ps -p $(cat /tmp/nextjs.pid 2>/dev/null) 2>/dev/null || echo 'NOT_RUNNING'")
print(f"Process check: {pid_check[:300]}")

# Проверка порта
code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print(f"Port check: {port_check[:400]}")

# Проверка логов
code, logs, _ = safe_run("tail -100 /tmp/nextjs-nohup.log 2>&1")
print("\nLogs:")
print(logs[:5000])

# Если порт слушается, тестируем
if "NOT_FOUND" not in port_check:
    print("\n[3] Port is listening! Testing...")
    code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=10)
    if response and len(response) > 50:
        print("[OK] Application is responding!")
        print(response[:700])
        
        # Если работает через nohup, создаем systemd service
        print("\n[4] Creating systemd service...")
        service_content = f"""[Unit]
Description=Next.js Admin Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory={REMOTE_DIR}
Environment="PORT=3000"
Environment="HOSTNAME=127.0.0.1"
Environment="NODE_ENV=development"
Environment="NEXT_TELEMETRY_DISABLED=1"
ExecStart=/usr/bin/npm run dev -- -p 3000 -H 127.0.0.1
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
"""
        sftp = ssh.open_sftp()
        try:
            with sftp.open("/etc/systemd/system/deti-admin.service", "w") as f:
                f.write(service_content)
            safe_run("systemctl daemon-reload")
            safe_run("systemctl enable deti-admin.service")
            safe_run("systemctl start deti-admin.service")
            print("Systemd service created and started")
        except Exception as e:
            print(f"Error creating service: {e}")
        finally:
            sftp.close()
    else:
        print("No response from application")
else:
    print("\n[3] Port not listening, checking why...")
    code, process_info, _ = safe_run("ps aux | grep -E 'node|next|npm' | grep -v grep")
    print("Processes:")
    print(process_info[:1000])

ssh.close()

print("\nDone!")
