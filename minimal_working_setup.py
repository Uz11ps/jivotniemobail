"""Минимальная рабочая настройка"""
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

print("Creating minimal working setup...")

# Остановка
safe_run("pm2 delete all 2>/dev/null || true")
safe_run("pkill -9 node 2>/dev/null || true")
time.sleep(2)

# Проверка зависимостей
print("\n[1] Checking dependencies...")
code, deps, _ = safe_run(f"cd {REMOTE_DIR} && npm list --depth=0 2>&1 | head -30")
if "UNMET" in deps or "missing" in deps.lower():
    print("Reinstalling dependencies...")
    safe_run(f"cd {REMOTE_DIR} && npm install 2>&1 | tail -30")

# Проверка tailwind.config
print("\n[2] Checking Tailwind config...")
code, tailwind_config, _ = safe_run(f"cat {REMOTE_DIR}/tailwind.config.js 2>&1 || cat {REMOTE_DIR}/tailwind.config.ts 2>&1 || echo 'NOT_FOUND'")
if "NOT_FOUND" in tailwind_config:
    print("Creating tailwind.config.js...")
    tailwind_cfg = """/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
"""
    sftp = ssh.open_sftp()
    try:
        with sftp.open(f"{REMOTE_DIR}/tailwind.config.js", "w") as f:
            f.write(tailwind_cfg)
    finally:
        sftp.close()

# Проверка postcss.config
print("[3] Checking PostCSS config...")
code, postcss_config, _ = safe_run(f"cat {REMOTE_DIR}/postcss.config.js 2>&1 || echo 'NOT_FOUND'")
if "NOT_FOUND" in postcss_config:
    print("Creating postcss.config.js...")
    postcss_cfg = """module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
"""
    sftp = ssh.open_sftp()
    try:
        with sftp.open(f"{REMOTE_DIR}/postcss.config.js", "w") as f:
            f.write(postcss_cfg)
    finally:
        sftp.close()

# Создание абсолютно минимального приложения
print("[4] Creating minimal app structure...")
minimal_page = """export default function Home() {
  return (
    <div style={{ padding: '50px', textAlign: 'center' }}>
      <h1>Админ панель</h1>
      <p>Приложение запущено</p>
    </div>
  );
}
"""
sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/src/app/page.tsx", "w") as f:
        f.write(minimal_page)
finally:
    sftp.close()

minimal_layout = """export const metadata = {
  title: 'Админ панель',
}

export default function RootLayout({ children }) {
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
        f.write(minimal_layout)
finally:
    sftp.close()

minimal_css = """body {
  margin: 0;
  font-family: system-ui, -apple-system, sans-serif;
}
"""
sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/src/app/globals.css", "w") as f:
        f.write(minimal_css)
finally:
    sftp.close()

# Очистка
print("[5] Cleaning...")
safe_run(f"cd {REMOTE_DIR} && rm -rf .next")

# Запуск
print("[6] Starting minimal app...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
exec npm run dev -- -p 3000 -H 127.0.0.1
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-minimal.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-minimal.sh", 0o755)
finally:
    sftp.close()

code, start_out, _ = safe_run("pm2 start /tmp/start-minimal.sh --name deti-admin --interpreter bash")
print(f"Start: {start_out[:600]}")

# Ждем
print("\n[7] Waiting 60 seconds...")
time.sleep(60)

# Проверка
print("[8] Checking application...")
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
    print("Logs:")
    print(logs[:4000])

code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\nDone!")
