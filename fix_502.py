"""Исправление ошибки 502 Bad Gateway"""
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
    return code, out, err

print("Исправление ошибки 502...")

# 1. Проверка логов PM2
print("\n1. Проверка логов приложения...")
code, out, err = cmd("pm2 logs deti-admin --lines 20 --nostream 2>&1")
print("Логи:")
print(out[:1000] if out else err[:500])

# 2. Остановка и перезапуск
print("\n2. Перезапуск приложения...")
cmd("pm2 delete deti-admin 2>/dev/null || true")
time.sleep(2)

# Проверяем наличие .env.local
code, _ = cmd(f"test -f {REMOTE_DIR}/.env.local && echo 'EXISTS' || echo 'MISSING'")
if "MISSING" in str(code):
    print("[WARN] .env.local отсутствует, создаю минимальный...")
    sftp = ssh.open_sftp()
    try:
        with sftp.open(f"{REMOTE_DIR}/.env.local", "w") as f:
            f.write("# Минимальная конфигурация\n")
            f.write("NEXT_PUBLIC_FIREBASE_API_KEY=placeholder\n")
            f.write("NEXT_PUBLIC_FIREBASE_PROJECT_ID=placeholder\n")
        print("[OK] Создан минимальный .env.local")
    except Exception as e:
        print(f"[ERROR] Не удалось создать: {e}")
    finally:
        sftp.close()

# Запуск в dev режиме
print("\n3. Запуск приложения...")
code, out, err = cmd(f"cd {REMOTE_DIR} && pm2 start npm --name deti-admin -- run dev")
print(out[:500] if out else err[:500])

time.sleep(5)

# 4. Проверка порта
print("\n4. Проверка порта 3000...")
for i in range(3):
    code, out, _ = cmd("curl -s http://127.0.0.1:3000 2>&1 | head -5")
    if "Next.js" in out or code == 0:
        print("[OK] Приложение отвечает!")
        print(out[:300])
        break
    else:
        print(f"Попытка {i+1}/3... жду 3 секунды")
        time.sleep(3)

# 5. Проверка процессов
print("\n5. Проверка процессов...")
code, out, _ = cmd("ps aux | grep -E 'node|npm|next' | grep -v grep")
print(out[:500])

# 6. PM2 статус
print("\n6. PM2 статус...")
code, out, _ = cmd("pm2 status")
print(out[:500])

# 7. Проверка через nginx
print("\n7. Проверка через nginx...")
time.sleep(2)
code, out, _ = cmd("curl -s -I http://127.0.0.1/ 2>&1 | head -3")
print(out[:200])

ssh.close()

print("\n" + "="*60)
print("Проверка завершена!")
print("="*60)
print("Если все еще 502:")
print("1. Проверьте логи: pm2 logs deti-admin")
print("2. Убедитесь что .env.local настроен правильно")
print("3. Проверьте что порт 3000 не занят другим процессом")
