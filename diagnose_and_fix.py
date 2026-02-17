"""Диагностика и исправление проблемы"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def run(c, timeout=120):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    return code, out, err

print("Diagnosing and fixing...")

# Остановка
run("pm2 delete all 2>/dev/null || true")
run("pkill -9 node || pkill -9 npm || true")
time.sleep(3)

# Освобождение порта
run("fuser -k 3000/tcp 2>/dev/null || true")
run("lsof -ti :3000 | xargs kill -9 2>/dev/null || true")
time.sleep(2)

# Проверка что порт свободен
code, port_check, _ = run("lsof -i :3000 2>/dev/null || echo 'FREE'")
if "FREE" not in port_check:
    print("Port still busy, killing more...")
    run("ss -K dst :3000 2>/dev/null || true")
    time.sleep(2)

# Проверка .env.local
print("\nChecking .env.local...")
code, env_check, _ = run(f"test -f {REMOTE_DIR}/.env.local && head -3 {REMOTE_DIR}/.env.local || echo 'MISSING'")
print(env_check[:300])

# Запуск напрямую через node для проверки ошибок
print("\nTrying direct start to see errors...")
code, direct_out, direct_err = run(f"cd {REMOTE_DIR} && timeout 15 npm run dev 2>&1", timeout=20)
print("Direct start output:")
print(direct_out[:1500] if direct_out else direct_err[:1000])

# Если direct start работает, запускаем через PM2 правильно
print("\nStarting via PM2 with proper command...")
# Используем прямой запуск через node_modules/.bin/next
start_cmd = f"cd {REMOTE_DIR} && PORT=3000 NODE_ENV=development pm2 start node_modules/.bin/next --name deti-admin -- dev -p 3000"
code, pm2_out, pm2_err = run(start_cmd)
print(f"PM2 start exit code: {code}")
if pm2_err:
    print(f"Error: {pm2_err[:500]}")

# Альтернатива - через npm напрямую
if code != 0:
    print("\nTrying alternative method...")
    # Создаем wrapper скрипт
    wrapper = """#!/bin/bash
cd /var/www/168-222-193-86.regru.cloud/data/www/deti-admin
export PORT=3000
export NODE_ENV=development
exec npm run dev
"""
    sftp = ssh.open_sftp()
    try:
        with sftp.open("/tmp/start-next.sh", "w") as f:
            f.write(wrapper)
        sftp.chmod("/tmp/start-next.sh", 0o755)
    finally:
        sftp.close()
    
    code, alt_out, alt_err = run("pm2 start /tmp/start-next.sh --name deti-admin --interpreter bash")
    print(f"Alternative method exit code: {code}")

# Ждем
print("\nWaiting 45 seconds for startup...")
time.sleep(45)

# Проверка
print("\nChecking application...")
for i in range(5):
    code, response, _ = run("curl -s http://127.0.0.1:3000 2>&1 | head -15", timeout=15)
    if code == 0 and (len(response) > 100 or "html" in response.lower() or "DOCTYPE" in response or "next" in response.lower()):
        print(f"[OK] Application is working! (attempt {i+1})")
        print(response[:400])
        break
    else:
        print(f"Attempt {i+1}/5...")
        time.sleep(5)

# Проверка процессов
print("\nChecking processes...")
code, procs, _ = run("ps aux | grep -E 'node|next|npm' | grep -v grep | head -5")
print(procs[:500])

# Проверка порта
code, port_info, _ = run("lsof -i :3000 2>/dev/null || ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print(f"\nPort 3000 info: {port_info[:300]}")

run("pm2 save")

ssh.close()

print("\nDone! Check http://168.222.193.86")
