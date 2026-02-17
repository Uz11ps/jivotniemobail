"""Финальное исправление 502 ошибки"""
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

print("Fixing 502 error...")

# Полная остановка
print("\n[1] Complete stop...")
safe_run("pm2 delete all 2>/dev/null || true")
safe_run("pkill -9 node 2>/dev/null || true")
safe_run("pkill -9 npm 2>/dev/null || true")
safe_run("pkill -9 next 2>/dev/null || true")
time.sleep(3)

# Освобождение порта
print("[2] Freeing port 3000...")
safe_run("fuser -k 3000/tcp 2>/dev/null || true")
safe_run("lsof -ti :3000 | xargs kill -9 2>/dev/null || true")
safe_run("ss -K dst :3000 2>/dev/null || true")
time.sleep(3)

# Проверка что порт свободен
code, port_check, _ = safe_run("lsof -i :3000 2>/dev/null || echo 'FREE'")
if "FREE" not in port_check:
    print("Port still busy, killing more...")
    safe_run("netstat -tlnp 2>/dev/null | grep :3000 | awk '{print $7}' | cut -d'/' -f1 | xargs kill -9 2>/dev/null || true")
    time.sleep(2)

# Проверка реальных ошибок - запуск напрямую
print("\n[3] Checking for real errors by running directly...")
code, direct_out, direct_err = safe_run(f"cd {REMOTE_DIR} && timeout 30 npm run dev 2>&1", timeout=35)
print("Direct run output:")
print(direct_out[:4000])
if direct_err and len(direct_err) > 50:
    print("\nDirect run errors:")
    print(direct_err[:3000])

# Если есть ошибки компиляции, исправляем их
if "error" in direct_out.lower() or "Error" in direct_out or "failed" in direct_out.lower():
    print("\n[4] Found errors, checking specific issues...")
    
    # Проверка зависимостей
    code, deps_check, _ = safe_run(f"cd {REMOTE_DIR} && npm list --depth=0 2>&1 | grep -E 'UNMET|missing|error' || echo 'OK'")
    if "OK" not in deps_check:
        print("Dependency issues found, reinstalling...")
        safe_run(f"cd {REMOTE_DIR} && npm install 2>&1 | tail -20")

# Создание простого тестового скрипта для проверки что Next.js может запуститься
print("\n[5] Creating test script...")
test_script = f"""#!/bin/bash
cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1

# Запуск с выводом в файл для диагностики
npm run dev -- -p 3000 -H 127.0.0.1 > /tmp/nextjs-startup.log 2>&1 &
NEXT_PID=$!
echo $NEXT_PID > /tmp/nextjs.pid

# Ждем 15 секунд
sleep 15

# Проверяем что процесс жив
if ps -p $NEXT_PID > /dev/null; then
    echo "Process is running"
    # Проверяем порт
    if ss -tlnp | grep :3000 > /dev/null; then
        echo "Port 3000 is listening"
        curl -s http://127.0.0.1:3000 | head -20
    else
        echo "Port 3000 is NOT listening"
        cat /tmp/nextjs-startup.log | tail -50
    fi
else
    echo "Process died"
    cat /tmp/nextjs-startup.log | tail -50
fi
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/test-nextjs.sh", "w") as f:
        f.write(test_script)
    sftp.chmod("/tmp/test-nextjs.sh", 0o755)
finally:
    sftp.close()

code, test_out, _ = safe_run("bash /tmp/test-nextjs.sh", timeout=60)
print("Test script output:")
print(test_out[:4000])

# Остановка тестового процесса
safe_run("pkill -f 'next dev' || true")
safe_run("kill $(cat /tmp/nextjs.pid 2>/dev/null) 2>/dev/null || true")
time.sleep(2)

# Если порт слушается в тесте, запускаем через PM2
if "Port 3000 is listening" in test_out:
    print("\n[6] Port works in test, starting via PM2...")
    start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
exec npm run dev -- -p 3000 -H 127.0.0.1
"""
    sftp = ssh.open_sftp()
    try:
        with sftp.open("/tmp/start-nextjs.sh", "w") as f:
            f.write(start_script)
        sftp.chmod("/tmp/start-nextjs.sh", 0o755)
    finally:
        sftp.close()
    
    code, pm2_start, _ = safe_run("pm2 start /tmp/start-nextjs.sh --name deti-admin --interpreter bash")
    print(f"PM2 start: {pm2_start[:600]}")
    
    # Ждем
    print("\n[7] Waiting 60 seconds...")
    time.sleep(60)
    
    # Проверка
    code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
    print(f"Port status: {port_check[:400]}")
    
    if "NOT_FOUND" not in port_check:
        print("\n[OK] Port is listening!")
        code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1 | head -30", timeout=10)
        if response and len(response) > 50:
            print(f"[OK] Application is responding!")
            print(response[:500])
        else:
            print("Application not responding yet")
    else:
        print("\n[WARN] Port still not listening, checking logs...")
        code, logs, _ = safe_run("pm2 logs deti-admin --lines 50 --nostream 2>&1", timeout=60)
        print(logs[:3000])
else:
    print("\n[6] Port did not work in test, checking startup log...")
    code, startup_log, _ = safe_run("cat /tmp/nextjs-startup.log 2>&1 | tail -100")
    print("Startup log:")
    print(startup_log[:4000])

# Финальный статус
code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:800])

safe_run("pm2 save")

ssh.close()

print("\n" + "="*60)
print("FIX COMPLETE!")
print("="*60)
