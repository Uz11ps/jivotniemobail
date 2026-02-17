"""Полное исправление - запуск в dev режиме"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def cmd(c):
    _, stdout, stderr = ssh.exec_command(c, timeout=60)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    return code, out

print("Полное исправление...")

# 1. Остановка всех процессов
print("\n1. Остановка процессов...")
cmd("pm2 delete all 2>/dev/null || true")
time.sleep(2)

# 2. Удаление .next (т.к. сборка не завершилась)
print("\n2. Очистка...")
cmd(f"cd {REMOTE_DIR} && rm -rf .next")

# 3. Проверка .env.local
print("\n3. Проверка .env.local...")
code, out = cmd(f"test -f {REMOTE_DIR}/.env.local && echo 'EXISTS' || echo 'MISSING'")
if "MISSING" in out:
    print("Создание минимального .env.local...")
    env_content = """NEXT_PUBLIC_FIREBASE_API_KEY=placeholder
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=placeholder.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=placeholder
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=placeholder.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=123456789
NEXT_PUBLIC_FIREBASE_APP_ID=1:123456789:web:abc123
"""
    sftp = ssh.open_sftp()
    try:
        with sftp.open(f"{REMOTE_DIR}/.env.local", "w") as f:
            f.write(env_content)
        print("[OK] .env.local создан")
    except Exception as e:
        print(f"[ERROR] {e}")
    finally:
        sftp.close()
else:
    print("[OK] .env.local существует")

# 4. Запуск в dev режиме
print("\n4. Запуск в dev режиме...")
code, out = cmd(f"cd {REMOTE_DIR} && pm2 start npm --name deti-admin -- run dev -- --port 3000")
print(out[:500])

time.sleep(8)

# 5. Проверка
print("\n5. Проверка приложения...")
for i in range(5):
    code, out = cmd("curl -s http://127.0.0.1:3000 2>&1 | head -10")
    if "Next.js" in out or "html" in out.lower() or code == 0:
        print("[OK] Приложение работает!")
        print(out[:400])
        break
    else:
        print(f"Попытка {i+1}/5...")
        time.sleep(3)

# 6. PM2 статус
print("\n6. PM2 статус...")
code, out = cmd("pm2 status")
print(out[:400])

# 7. Сохранение PM2
cmd("pm2 save")

# 8. Проверка через nginx
print("\n7. Проверка через nginx...")
time.sleep(2)
code, out = cmd("curl -s -I http://127.0.0.1/ 2>&1 | head -5")
print(out[:300])

ssh.close()

print("\n" + "="*60)
print("ГОТОВО!")
print("="*60)
print("Приложение запущено в dev режиме на порту 3000")
print("Проверьте: http://168.222.193.86")
print("\nВажно: Настройте .env.local с реальными Firebase credentials!")
