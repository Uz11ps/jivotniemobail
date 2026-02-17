"""Исправление конфигурации Firebase"""
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
    return code, safe_out[:3000], safe_err[:1500]

print("Fixing Firebase configuration...")

# Остановка
safe_run("pm2 delete all 2>/dev/null || true")
time.sleep(2)

# Проверка текущего .env.local
print("\n[1] Checking current .env.local...")
code, env_current, _ = safe_run(f"cat {REMOTE_DIR}/.env.local 2>/dev/null || echo 'MISSING'")
print(env_current[:500])

# Исправление admin.ts для безопасной инициализации
print("\n[2] Fixing admin.ts for safe initialization...")
admin_ts_content = """import * as admin from 'firebase-admin';

// Безопасная инициализация только если есть все необходимые переменные
if (!admin.apps.length) {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (projectId && clientEmail && privateKey) {
    try {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          clientEmail,
          privateKey: privateKey.replace(/\\\\n/g, '\\n'),
        }),
      });
    } catch (error) {
      console.error('Firebase Admin initialization error:', error);
    }
  } else {
    console.warn('Firebase Admin credentials not provided, admin features will be disabled');
  }
}

export const adminAuth = admin.apps.length > 0 ? admin.auth() : null;
export const adminDb = admin.apps.length > 0 ? admin.firestore() : null;
export const adminStorage = admin.apps.length > 0 ? admin.storage() : null;
"""
sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/src/lib/firebase/admin.ts", "w") as f:
        f.write(admin_ts_content)
    print("  admin.ts updated")
except Exception as e:
    print(f"  Error: {e}")
finally:
    sftp.close()

# Создание минимального .env.local с placeholder значениями
print("\n[3] Creating minimal .env.local...")
env_content = """NEXT_PUBLIC_FIREBASE_API_KEY=AIzaSyPlaceholder
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=placeholder.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=placeholder-project
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=placeholder-project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=123456789
NEXT_PUBLIC_FIREBASE_APP_ID=1:123456789:web:placeholder

# Admin SDK (optional for dev)
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
"""
sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/.env.local", "w") as f:
        f.write(env_content)
    print("  .env.local created")
except Exception as e:
    print(f"  Error: {e}")
finally:
    sftp.close()

# Очистка
print("\n[4] Cleaning...")
safe_run(f"cd {REMOTE_DIR} && rm -rf .next")

# Запуск
print("\n[5] Starting application...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
npm run dev -- -p 3000 -H 127.0.0.1
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-safe.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-safe.sh", 0o755)
finally:
    sftp.close()

code, start_out, _ = safe_run("pm2 start /tmp/start-safe.sh --name deti-admin --interpreter bash")
print(f"Start: {start_out[:500]}")

# Ждем
print("\n[6] Waiting 90 seconds...")
time.sleep(90)

# Проверка
print("\n[7] Checking application...")
for i in range(20):
    code, response, _ = safe_run("curl -s -m 10 http://127.0.0.1:3000 2>&1", timeout=15)
    if code == 0 and response and (len(response) > 100 or "html" in response.lower() or "DOCTYPE" in response):
        print(f"[OK] Application is working! (attempt {i+1})")
        print(response[:700])
        break
    else:
        if i < 19:
            print(f"Attempt {i+1}/20... waiting 5 seconds")
            time.sleep(5)

# Проверка порта
code, port, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print(f"\nPort status: {port[:300]}")

# Статус
code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\n" + "="*60)
print("COMPLETE!")
print("="*60)
print("Application should be running")
print("Check: http://168.222.193.86")
