"""Запуск приложения без проблем с кодировкой"""
import paramiko
import time
import sys

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

# Устанавливаем UTF-8 для вывода
if sys.platform == 'win32':
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, errors='replace')
    sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, errors='replace')

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def cmd(c):
    _, stdout, stderr = ssh.exec_command(c, timeout=60)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    return code, out

print("Запуск приложения...")

# Остановка
cmd("pm2 delete deti-admin 2>/dev/null || true")
time.sleep(2)

# Очистка
cmd(f"cd {REMOTE_DIR} && rm -rf .next")

# Запуск
print("Запуск в dev режиме...")
code, out = cmd(f"cd {REMOTE_DIR} && pm2 start npm --name deti-admin -- run dev")
print("PM2 запущен")

time.sleep(10)

# Проверка
print("Проверка...")
code, out = cmd("curl -s http://127.0.0.1:3000 2>&1 | head -5")
if "Next.js" in out or "html" in out.lower():
    print("[OK] Приложение работает!")
else:
    print("[WARN] Проверьте логи: pm2 logs deti-admin")

cmd("pm2 save")

ssh.close()
print("Готово! Проверьте: http://168.222.193.86")
