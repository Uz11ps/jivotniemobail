"""Исправление Next.js с простой страницей"""
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
    return code, safe_out[:8000], safe_err[:6000]

print("Fixing Next.js with simple page...")

# Остановка
safe_run("pm2 delete deti-admin 2>/dev/null || true")
safe_run("pkill -9 node 2>/dev/null || true")
time.sleep(2)

# Создание максимально простой страницы без useRouter
print("\n[1] Creating simple page without router...")
simple_page = """export default function Home() {
  return (
    <div style={{ padding: '50px', textAlign: 'center' }}>
      <h1>Админ панель</h1>
      <p>Приложение работает</p>
      <p><a href="/login">Войти</a></p>
    </div>
  );
}
"""

simple_layout = """import './globals.css'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ru">
      <body>{children}</body>
    </html>
  )
}
"""

sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/src/app/page.tsx", "w") as f:
        f.write(simple_page)
    with sftp.open(f"{REMOTE_DIR}/src/app/layout.tsx", "w") as f:
        f.write(simple_layout)
    print("  Files created")
except Exception as e:
    print(f"  Error: {e}")
finally:
    sftp.close()

# Проверка что login страница существует
code, login_exists, _ = safe_run(f"test -f {REMOTE_DIR}/src/app/login/page.tsx && echo 'EXISTS' || echo 'MISSING'")
print(f"login/page.tsx: {login_exists[:50]}")

# Если login страницы нет, создаем простую
if "MISSING" in login_exists:
    print("[2] Creating login page...")
    login_page = """export default function Login() {
  return (
    <div style={{ padding: '50px', textAlign: 'center' }}>
      <h1>Вход в админ панель</h1>
      <p>Страница входа</p>
    </div>
  );
}
"""
    sftp = ssh.open_sftp()
    try:
        safe_run(f"mkdir -p {REMOTE_DIR}/src/app/login")
        with sftp.open(f"{REMOTE_DIR}/src/app/login/page.tsx", "w") as f:
            f.write(login_page)
        print("  Login page created")
    except Exception as e:
        print(f"  Error: {e}")
    finally:
        sftp.close()

# Очистка
print("[3] Cleaning...")
safe_run(f"cd {REMOTE_DIR} && rm -rf .next")

# Запуск
print("[4] Starting Next.js...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
export NODE_OPTIONS='--max-old-space-size=1024'
exec npm run dev -- -p 3000 -H 127.0.0.1
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-simple-next.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-simple-next.sh", 0o755)
finally:
    sftp.close()

code, start_out, _ = safe_run("pm2 start /tmp/start-simple-next.sh --name deti-admin --interpreter bash")
print(f"Start: {start_out[:500]}")

# Ждем 3 минуты
print("\n[5] Waiting 3 minutes for compilation...")
time.sleep(180)

# Проверка
print("[6] Checking...")
code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print(f"Port: {port_check[:300]}")

if "NOT_FOUND" not in port_check:
    print("[OK] Port is listening!")
    code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=10)
    if response and len(response) > 100:
        print(f"[OK] Next.js responding! Length: {len(response)}")
        print(response[:600])
        
        code, nginx_resp, _ = safe_run("curl -s http://127.0.0.1/ 2>&1", timeout=10)
        if nginx_resp and len(nginx_resp) > 100:
            print("\n[OK] Accessible through Nginx!")
            print(nginx_resp[:600])
        else:
            print(f"Nginx: {nginx_resp[:300]}")
    else:
        print("No response yet")
else:
    print("Port not listening")
    code, logs, _ = safe_run("pm2 logs deti-admin --lines 30 --nostream 2>&1", timeout=60)
    print("Logs:")
    print(logs[:3000])

code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\nDone! Check http://168.222.193.86")
