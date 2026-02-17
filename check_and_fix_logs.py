"""Проверка логов и исправление"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def run(c, timeout=60):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    return code, out, err

print("Checking logs and fixing...")

# Проверка логов
print("\n[1] Checking error logs...")
code, err_logs, _ = run("pm2 logs deti-admin --err --lines 30 --nostream 2>&1", timeout=60)
print("Error logs:")
print(err_logs[:2000] if err_logs else "No error logs")

# Проверка что именно падает
print("\n[2] Checking what's failing...")
code, out_logs, _ = run("pm2 logs deti-admin --out --lines 20 --nostream 2>&1", timeout=60)
print("Output logs:")
print(out_logs[:1500] if out_logs else "No output logs")

# Проверка .env.local
print("\n[3] Checking .env.local...")
code, env_content, _ = run(f"cat {REMOTE_DIR}/.env.local 2>/dev/null || echo 'MISSING'")
print(env_content[:500])

# Проверка package.json scripts
print("\n[4] Checking package.json...")
code, pkg_scripts, _ = run(f"grep -A 5 'scripts' {REMOTE_DIR}/package.json")
print(pkg_scripts[:500])

# Остановка и перезапуск с правильной командой
print("\n[5] Restarting with correct command...")
run("pm2 delete deti-admin 2>/dev/null || true")
time.sleep(2)

# Запуск с явным указанием всех переменных
start_cmd = f"cd {REMOTE_DIR} && PORT=3000 NODE_ENV=development NEXT_TELEMETRY_DISABLED=1 pm2 start 'npm run dev' --name deti-admin"
code, start_out, start_err = run(start_cmd)
print(f"Start exit code: {code}")

# Ждем
print("\n[6] Waiting 45 seconds...")
time.sleep(45)

# Проверка
print("\n[7] Checking...")
code, response, _ = run("curl -s http://127.0.0.1:3000 2>&1 | head -15", timeout=15)
if code == 0 and (len(response) > 100 or "html" in response.lower() or "DOCTYPE" in response):
    print("[OK] Application is working!")
    print(response[:400])
else:
    print("[WARN] Application may still be starting or has errors")
    print(f"Response length: {len(response) if response else 0}")

# Финальный статус
code, status, _ = run("pm2 list")
print("\nFinal PM2 status:")
safe_status = status.encode('ascii', errors='ignore').decode('ascii')
print(safe_status[:600])

run("pm2 save")

ssh.close()

print("\nDone!")
