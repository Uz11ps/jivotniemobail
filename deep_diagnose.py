"""Глубокая диагностика проблемы"""
import paramiko
import time

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
    # Безопасный вывод
    safe_out = out.encode('ascii', errors='ignore').decode('ascii')
    safe_err = err.encode('ascii', errors='ignore').decode('ascii')
    return code, safe_out[:2000], safe_err[:1000]

print("Deep diagnosis...")

# Остановка
safe_run("pm2 delete all 2>/dev/null || true")
time.sleep(2)

# Проверка что порт свободен
print("\n[1] Checking port 3000...")
code, port_check, _ = safe_run("lsof -i :3000 2>/dev/null || ss -tlnp | grep :3000 || echo 'FREE'")
print(f"Port status: {port_check[:400]}")

# Проверка зависимостей
print("\n[2] Checking node_modules...")
code, nm_check, _ = safe_run(f"test -d {REMOTE_DIR}/node_modules && echo 'EXISTS' || echo 'MISSING'")
print(f"node_modules: {nm_check[:100]}")

# Попытка запуска напрямую для просмотра ошибок
print("\n[3] Trying direct start to see errors...")
code, direct, _ = safe_run(f"cd {REMOTE_DIR} && timeout 20 npm run dev 2>&1", timeout=25)
print("Direct start output:")
print(direct[:2000])

# Проверка package.json
print("\n[4] Checking package.json dev script...")
code, pkg, _ = safe_run(f"grep -A 2 '\"dev\"' {REMOTE_DIR}/package.json")
print(pkg[:300])

# Проверка .next
print("\n[5] Checking .next directory...")
code, next_check, _ = safe_run(f"ls -la {REMOTE_DIR}/.next 2>/dev/null | head -5 || echo 'NOT_EXISTS'")
print(next_check[:400])

# Если .next не существует или пуст, это нормально для dev режима
# Но если приложение пытается запуститься в production, это проблема

# Запуск через PM2 с максимальным выводом
print("\n[6] Starting via PM2 with verbose output...")
start_cmd = f"""cd {REMOTE_DIR}
export PORT=3000
export NODE_ENV=development
export DEBUG=*
npm run dev
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-verbose.sh", "w") as f:
        f.write(start_cmd)
    sftp.chmod("/tmp/start-verbose.sh", 0o755)
finally:
    sftp.close()

code, pm2_start, _ = safe_run("pm2 start /tmp/start-verbose.sh --name deti-admin --interpreter bash --log-date-format 'YYYY-MM-DD HH:mm:ss'")
print(f"PM2 start: {pm2_start[:500]}")

# Ждем
print("\n[7] Waiting 40 seconds...")
time.sleep(40)

# Проверка логов
print("\n[8] Checking logs...")
code, logs, _ = safe_run("pm2 logs deti-admin --lines 40 --nostream 2>&1", timeout=60)
print("Recent logs:")
print(logs[:2500])

# Проверка приложения
print("\n[9] Checking application...")
code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1 | head -20", timeout=15)
if response and len(response) > 50:
    print(f"Response received: {response[:400]}")
else:
    print("No response or error")

# Статус
code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\nDiagnosis complete!")
