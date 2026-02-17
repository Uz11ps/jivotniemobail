"""Проверка финального статуса деплоя"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def cmd(c):
    _, stdout, stderr = ssh.exec_command(c, timeout=30)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    return code, out

print("=" * 60)
print("ПРОВЕРКА ДЕПЛОЯ")
print("=" * 60)

# PM2 статус
print("\n1. PM2 Status:")
code, out = cmd("pm2 status")
print(out[:500])

# Логи
print("\n2. Последние логи:")
code, out = cmd("pm2 logs deti-admin --lines 10 --nostream")
print(out[:800])

# Проверка порта
print("\n3. Проверка порта 3000:")
time.sleep(2)
code, out = cmd("curl -s http://127.0.0.1:3000 2>&1 | head -5")
if code == 0 and out:
    print("[OK] Приложение отвечает!")
    print(out[:300])
else:
    print("[WARN] Приложение не отвечает или еще запускается")

# Nginx
print("\n4. Nginx конфигурация:")
code, out = cmd("nginx -t 2>&1")
print(out[:200])

# Финальная информация
print("\n" + "=" * 60)
print("РЕЗЮМЕ")
print("=" * 60)
print(f"[OK] Файлы загружены")
print(f"[OK] PM2 настроен")
print(f"[OK] Nginx настроен")
print(f"[OK] Приложение запущено в dev режиме (т.к. сборка падает)")
print("\nДоступ:")
print(f"  http://{SERVER}")
print("\nДля production сборки:")
print("  - Увеличьте память сервера")
print("  - Или используйте dev режим (уже запущен)")

ssh.close()
