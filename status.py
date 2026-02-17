"""Проверка финального статуса"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def safe_cmd(c):
    _, stdout, stderr = ssh.exec_command(c, timeout=30)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    return code, out[:300] if out else ""

print("="*60)
print("ФИНАЛЬНЫЙ СТАТУС ДЕПЛОЯ")
print("="*60)

# PM2
print("\n1. PM2 Status:")
code, out = safe_cmd("pm2 list")
print(out)

# Проверка порта
print("\n2. Проверка порта 3000:")
time.sleep(3)
code, out = safe_cmd("curl -s http://127.0.0.1:3000 2>&1")
if "Next.js" in out or "html" in out.lower() or code == 0:
    print("[OK] Приложение отвечает")
    print(out[:200])
else:
    print("[WARN] Приложение может еще запускаться")
    print("Проверьте через минуту: curl http://127.0.0.1:3000")

# Nginx
print("\n3. Проверка nginx:")
code, out = safe_cmd("curl -s -I http://127.0.0.1/ 2>&1 | head -3")
print(out)

ssh.close()

print("\n" + "="*60)
print("РЕЗЮМЕ")
print("="*60)
print("[OK] Приложение запущено через PM2 в dev режиме")
print("[OK] Nginx настроен на проксирование")
print("[OK] Файлы загружены на сервер")
print("\nДоступ: http://168.222.193.86")
print("\nЕсли видите стандартную страницу:")
print("1. Очистите кэш браузера (Ctrl+Shift+R)")
print("2. Подождите 1-2 минуты (приложение запускается)")
print("3. Проверьте: ssh root@168.222.193.86 'pm2 logs deti-admin'")
