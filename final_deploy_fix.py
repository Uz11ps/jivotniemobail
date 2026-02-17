"""Финальное исправление без проблем с выводом"""
import paramiko
import time
import sys

# Настройка UTF-8
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def run(c, timeout=120):
    try:
        _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
        code = stdout.channel.recv_exit_status()
        out = stdout.read().decode(errors="replace", encoding="utf-8")
        err = stderr.read().decode(errors="replace", encoding="utf-8")
        return code, out[:1500], err[:500]
    except Exception as e:
        return -1, "", str(e)

print("Final deployment fix...")

# Полная очистка
print("\n[1] Complete cleanup...")
run("pm2 delete all 2>/dev/null || true")
run("pm2 kill 2>/dev/null || true")
run("pkill -9 node 2>/dev/null || true")
run("pkill -9 npm 2>/dev/null || true")
run("pkill -9 next 2>/dev/null || true")
time.sleep(4)

# Освобождение порта
print("[2] Freeing port 3000...")
run("fuser -k 3000/tcp 2>/dev/null || true")
run("lsof -ti :3000 | xargs kill -9 2>/dev/null || true")
time.sleep(3)

# Проверка порта
code, port_check, _ = run("lsof -i :3000 2>/dev/null || echo 'FREE'")
if "FREE" not in port_check:
    print("  Port still busy, trying ss...")
    run("ss -K dst :3000 2>/dev/null || true")
    time.sleep(2)

# Создание правильного .env.local если нужно
print("[3] Ensuring .env.local exists...")
code, env_check, _ = run(f"test -f {REMOTE_DIR}/.env.local && echo 'EXISTS' || echo 'MISSING'")
if "MISSING" in env_check:
    env_content = """NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=123456789
NEXT_PUBLIC_FIREBASE_APP_ID=1:123456789:web:abc123
"""
    sftp = ssh.open_sftp()
    try:
        with sftp.open(f"{REMOTE_DIR}/.env.local", "w") as f:
            f.write(env_content)
        print("  Created .env.local")
    except Exception as e:
        print(f"  Error: {e}")
    finally:
        sftp.close()

# Запуск
print("[4] Starting application...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
exec npm run dev
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-app.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-app.sh", 0o755)
finally:
    sftp.close()

code, start_out, start_err = run("pm2 start /tmp/start-app.sh --name deti-admin --interpreter bash")
print(f"  Exit code: {code}")

# Ждем
print("[5] Waiting 50 seconds for startup...")
time.sleep(50)

# Проверка
print("[6] Checking application...")
for i in range(8):
    code, response, _ = run("curl -s http://127.0.0.1:3000 2>&1", timeout=15)
    if code == 0 and response and (len(response) > 100 or "html" in response.lower() or "DOCTYPE" in response or "next" in response.lower()):
        print(f"  [OK] Application is working! (attempt {i+1})")
        print(f"  Response preview: {response[:300]}")
        break
    else:
        if i < 7:
            print(f"  Attempt {i+1}/8... waiting 5 seconds")
            time.sleep(5)

# Статус
code, status, _ = run("pm2 list")
print("\nPM2 Status:")
print(status[:800])

# Проверка порта
code, port_info, _ = run("lsof -i :3000 2>/dev/null || ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print(f"\nPort 3000: {port_info[:300]}")

run("pm2 save")

ssh.close()

print("\n" + "="*60)
print("COMPLETE!")
print("="*60)
print("Check: http://168.222.193.86")
print("\nIf still 502, wait 1-2 minutes and check:")
print("  ssh root@168.222.193.86")
print("  pm2 logs deti-admin --lines 30")
print("  curl http://127.0.0.1:3000")
