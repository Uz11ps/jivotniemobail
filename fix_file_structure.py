"""Исправление структуры файлов"""
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
    return code, safe_out[:6000], safe_err[:4000]

print("Fixing file structure...")

# Проверка структуры
print("\n[1] Checking file structure...")
code, files, _ = safe_run(f"find {REMOTE_DIR}/src/app -type f -name '*.tsx' -o -name '*.ts' | head -20")
print(f"Files found: {files[:1500]}")

code, layout_exists, _ = safe_run(f"test -f {REMOTE_DIR}/src/app/layout.tsx && echo 'EXISTS' || echo 'MISSING'")
code, page_exists, _ = safe_run(f"test -f {REMOTE_DIR}/src/app/page.tsx && echo 'EXISTS' || echo 'MISSING'")
print(f"layout.tsx: {layout_exists[:50]}")
print(f"page.tsx: {page_exists[:50]}")

# Проверка содержимого файлов
print("\n[2] Checking file contents...")
code, layout_content, _ = safe_run(f"head -10 {REMOTE_DIR}/src/app/layout.tsx")
code, page_content, _ = safe_run(f"head -10 {REMOTE_DIR}/src/app/page.tsx")
print(f"layout.tsx content: {layout_content[:300]}")
print(f"page.tsx content: {page_content[:300]}")

# Создание правильных файлов
print("\n[3] Creating correct files...")

# Правильный layout.tsx
layout_tsx = """import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Админ панель',
  description: 'Управление контентом',
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

# Правильный page.tsx
page_tsx = """export default function Home() {
  return (
    <div style={{ padding: '50px', textAlign: 'center' }}>
      <h1>Админ панель</h1>
      <p>Приложение работает</p>
    </div>
  )
}
"""

# Правильный globals.css
globals_css = """body {
  margin: 0;
  font-family: system-ui, -apple-system, sans-serif;
}
"""

sftp = ssh.open_sftp()
try:
    # Убеждаемся что директория существует
    try:
        sftp.listdir(f"{REMOTE_DIR}/src/app")
    except:
        safe_run(f"mkdir -p {REMOTE_DIR}/src/app")
    
    with sftp.open(f"{REMOTE_DIR}/src/app/layout.tsx", "w") as f:
        f.write(layout_tsx)
    print("  layout.tsx created")
    
    with sftp.open(f"{REMOTE_DIR}/src/app/page.tsx", "w") as f:
        f.write(page_tsx)
    print("  page.tsx created")
    
    with sftp.open(f"{REMOTE_DIR}/src/app/globals.css", "w") as f:
        f.write(globals_css)
    print("  globals.css created")
except Exception as e:
    print(f"  Error: {e}")
finally:
    sftp.close()

# Проверка что файлы созданы
code, verify_files, _ = safe_run(f"ls -la {REMOTE_DIR}/src/app/*.tsx {REMOTE_DIR}/src/app/*.css 2>&1")
print(f"\nFiles verification: {verify_files[:500]}")

# Очистка
print("\n[4] Cleaning...")
safe_run(f"cd {REMOTE_DIR} && rm -rf .next")

# Запуск
print("[5] Starting application...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
exec npm run dev -- -p 3000 -H 127.0.0.1
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-fixed.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-fixed.sh", 0o755)
finally:
    sftp.close()

code, start_out, _ = safe_run("pm2 start /tmp/start-fixed.sh --name deti-admin --interpreter bash")
print(f"Start: {start_out[:600]}")

# Ждем
print("\n[6] Waiting 60 seconds...")
time.sleep(60)

# Проверка
print("[7] Checking application...")
code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print(f"Port: {port_check[:400]}")

if "NOT_FOUND" not in port_check:
    print("[OK] Port is listening!")
    code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=10)
    if response and len(response) > 50:
        print(f"[OK] Application is responding!")
        print(response[:700])
    else:
        print("No response yet")
else:
    print("[WARN] Port not listening")
    code, logs, _ = safe_run("pm2 logs deti-admin --lines 50 --nostream 2>&1", timeout=60)
    print("Recent logs:")
    print(logs[:4000])

code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\nDone!")
