"""Проверка статуса и исправление проблем"""
import paramiko

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def cmd(c):
    try:
        _, stdout, stderr = ssh.exec_command(c, timeout=60)
        code = stdout.channel.recv_exit_status()
        out = stdout.read().decode(errors="replace", encoding="utf-8")
        err = stderr.read().decode(errors="replace", encoding="utf-8")
        print(f"\n[{code}] {c}")
        if out.strip():
            try:
                safe_out = out[:500].encode('ascii', errors='ignore').decode('ascii')
                print(safe_out)
            except:
                print("(вывод содержит специальные символы)")
        if err.strip() and code != 0:
            try:
                safe_err = err[:200].encode('ascii', errors='ignore').decode('ascii')
                print(f"ERROR: {safe_err}")
            except:
                print("ERROR: (ошибка содержит специальные символы)")
        return code, out
    except Exception as e:
        print(f"Exception: {e}")
        return -1, ""

print("Проверка статуса...")

# Проверка PM2
print("\n=== PM2 Status ===")
cmd("pm2 status")

# Проверка логов
print("\n=== PM2 Logs (последние 30 строк) ===")
cmd("pm2 logs deti-admin --lines 30 --nostream")

# Проверка порта
print("\n=== Проверка порта 3000 ===")
cmd("netstat -tlnp | grep 3000")

# Проверка файлов
print("\n=== Проверка файлов ===")
cmd(f"ls -la {REMOTE_DIR}/.next 2>/dev/null | head -5")
cmd(f"test -f {REMOTE_DIR}/.next/BUILD_ID && echo 'BUILD exists' || echo 'BUILD missing'")

# Попытка запуска без сборки (если .next существует)
code, _ = cmd(f"test -d {REMOTE_DIR}/.next && echo 'exists' || echo 'missing'")
if "exists" in str(code):
    print("\n[OK] Директория .next существует, приложение должно работать")
else:
    print("\n[WARN] Директория .next отсутствует, нужна сборка")

# Проверка .env
print("\n=== Проверка .env.local ===")
cmd(f"test -f {REMOTE_DIR}/.env.local && echo 'EXISTS' || echo 'MISSING - нужно создать!'")

ssh.close()
