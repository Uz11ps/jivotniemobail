"""Исправление layout и запуск"""
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
    return code, safe_out[:5000], safe_err[:3000]

print("Fixing layout and starting...")

# Остановка
safe_run("pm2 delete all 2>/dev/null || true")
time.sleep(2)

# Упрощение layout.tsx - убираем AuthProvider временно
print("\n[1] Simplifying layout.tsx...")
simple_layout = """import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Дети и Животные - Админ панель',
  description: 'Управление контентом приложения',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ru">
      <body>{children}</body>
    </html>
  )
}
"""
sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/src/app/layout.tsx", "w") as f:
        f.write(simple_layout)
    print("  layout.tsx simplified")
except Exception as e:
    print(f"  Error: {e}")
finally:
    sftp.close()

# Проверка globals.css
print("[2] Checking globals.css...")
code, globals, _ = safe_run(f"cat {REMOTE_DIR}/src/app/globals.css 2>&1")
if not globals or len(globals) < 10:
    print("  Creating minimal globals.css...")
    minimal_css = """@tailwind base;
@tailwind components;
@tailwind utilities;
"""
    sftp = ssh.open_sftp()
    try:
        with sftp.open(f"{REMOTE_DIR}/src/app/globals.css", "w") as f:
            f.write(minimal_css)
    finally:
        sftp.close()

# Очистка
print("[3] Cleaning...")
safe_run(f"cd {REMOTE_DIR} && rm -rf .next")

# Запуск напрямую через node для просмотра реальных ошибок
print("[4] Starting directly to see real errors...")
start_direct = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
timeout 90 npm run dev -- -p 3000 -H 127.0.0.1 2>&1 | tee /tmp/nextjs-real.log &
NEXT_PID=$!
sleep 20
if ps -p $NEXT_PID > /dev/null; then
    echo "Process running after 20s"
    ss -tlnp | grep :3000 || echo "Port not listening"
    sleep 10
    curl -s http://127.0.0.1:3000 | head -20 || echo "No response"
    kill $NEXT_PID 2>/dev/null || true
else
    echo "Process died"
    cat /tmp/nextjs-real.log | tail -100
fi
"""
code, direct_test, _ = safe_run(start_direct, timeout=100)
print("Direct test output:")
print(direct_test[:4000])

# Если работает напрямую, запускаем через PM2
if "Port not listening" not in direct_test or "Process died" in direct_test:
    print("\n[5] Direct test failed, checking log...")
    code, log_content, _ = safe_run("cat /tmp/nextjs-real.log 2>&1 | tail -150")
    print("Real log:")
    print(log_content[:5000])
else:
    print("\n[5] Direct test worked, starting via PM2...")
    start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
exec npm run dev -- -p 3000 -H 127.0.0.1
"""
    sftp = ssh.open_sftp()
    try:
        with sftp.open("/tmp/start-final.sh", "w") as f:
            f.write(start_script)
        sftp.chmod("/tmp/start-final.sh", 0o755)
    finally:
        sftp.close()
    
    code, pm2_start, _ = safe_run("pm2 start /tmp/start-final.sh --name deti-admin --interpreter bash")
    print(f"PM2 start: {pm2_start[:600]}")
    
    # Ждем
    print("\n[6] Waiting 60 seconds...")
    time.sleep(60)
    
    # Проверка
    code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
    print(f"Port: {port_check[:400]}")
    
    if "NOT_FOUND" not in port_check:
        print("[OK] Port is listening!")
        code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=10)
        if response and len(response) > 50:
            print(f"[OK] Application is responding!")
            print(response[:600])
    else:
        print("[WARN] Port not listening")
        code, logs, _ = safe_run("pm2 logs deti-admin --lines 40 --nostream 2>&1", timeout=60)
        print(logs[:3000])

code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\nDone!")
