"""Проверка прямого запуска"""
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
    return code, safe_out[:6000], safe_err[:4000]

print("Direct start check...")

# Остановка PM2
safe_run("pm2 delete all 2>/dev/null || true")
time.sleep(2)

# Освобождение порта
safe_run("fuser -k 3000/tcp 2>/dev/null || true")
safe_run("lsof -ti :3000 | xargs kill -9 2>/dev/null || true")
time.sleep(2)

# Запуск в фоне напрямую и проверка через несколько секунд
print("\n[1] Starting directly in background...")
start_cmd = f"cd {REMOTE_DIR} && PORT=3000 HOSTNAME=127.0.0.1 NODE_ENV=development npm run dev -- -p 3000 -H 127.0.0.1 > /tmp/nextjs.log 2>&1 &"
safe_run(start_cmd)
time.sleep(10)

# Проверка порта
print("\n[2] Checking port after 10 seconds...")
code, port, _ = safe_run("ss -tlnp | grep :3000 || lsof -i :3000 || echo 'NOT_FOUND'")
print(f"Port: {port[:500]}")

# Проверка логов
print("\n[3] Checking direct logs...")
code, logs, _ = safe_run("tail -100 /tmp/nextjs.log 2>&1")
print("Logs:")
print(logs[:4000])

# Проверка процессов
code, procs, _ = safe_run("ps aux | grep -E 'next|node.*3000' | grep -v grep")
print("\nProcesses:")
print(procs[:800])

# Тест запроса
print("\n[4] Testing request...")
code, response, _ = safe_run("curl -s -m 5 http://127.0.0.1:3000 2>&1", timeout=10)
if response and len(response) > 50:
    print(f"[OK] Got response! Length: {len(response)}")
    print(response[:600])
else:
    print(f"No response: {response[:300]}")

# Остановка фонового процесса
safe_run("pkill -f 'next dev' || true")

ssh.close()

print("\nDone!")
