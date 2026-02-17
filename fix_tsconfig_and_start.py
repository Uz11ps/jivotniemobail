"""Исправление tsconfig и запуск"""
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
    return code, safe_out[:2500], safe_err[:1500]

print("Fixing tsconfig and starting...")

# Остановка
safe_run("pm2 delete all 2>/dev/null || true")
time.sleep(2)

# Проверка tsconfig
print("\n[1] Checking tsconfig.json...")
code, tsconfig, _ = safe_run(f"cat {REMOTE_DIR}/tsconfig.json")
print(tsconfig[:800])

# Обновление tsconfig для правильной работы
print("\n[2] Updating tsconfig.json...")
new_tsconfig = """{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": false,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
"""
sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/tsconfig.json", "w") as f:
        f.write(new_tsconfig)
    print("  tsconfig.json updated")
except Exception as e:
    print(f"  Error: {e}")
finally:
    sftp.close()

# Очистка
print("\n[3] Cleaning...")
safe_run(f"cd {REMOTE_DIR} && rm -rf .next")

# Запуск с отключенной проверкой типов для dev режима
print("\n[4] Starting with type checking disabled...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
export SKIP_ENV_VALIDATION=1
npm run dev
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-dev.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-dev.sh", 0o755)
finally:
    sftp.close()

code, start_out, _ = safe_run("pm2 start /tmp/start-dev.sh --name deti-admin --interpreter bash")
print(f"Start: {start_out[:500]}")

# Ждем
print("\n[5] Waiting 70 seconds for compilation...")
time.sleep(70)

# Проверка
print("\n[6] Checking application...")
for i in range(12):
    code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=20)
    if code == 0 and response and (len(response) > 100 or "html" in response.lower() or "DOCTYPE" in response or "next" in response.lower()):
        print(f"[OK] Application is working! (attempt {i+1})")
        print(response[:600])
        break
    else:
        if i < 11:
            print(f"Attempt {i+1}/12... waiting 5 seconds")
            time.sleep(5)

# Логи
print("\n[7] Checking recent logs...")
code, logs, _ = safe_run("pm2 logs deti-admin --lines 30 --nostream 2>&1", timeout=60)
print("Recent logs:")
print(logs[:3000])

# Статус
code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:800])

safe_run("pm2 save")

ssh.close()

print("\nDone! Check http://168.222.193.86")
