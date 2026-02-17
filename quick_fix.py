"""Быстрое исправление порта"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def run(c):
    _, stdout, _ = ssh.exec_command(c, timeout=60)
    code = stdout.channel.recv_exit_status()
    return code

print("Quick fix...")

# Остановка
run("pm2 delete all 2>/dev/null || true")
run("pkill -f 'next' || pkill -f 'node.*300' || true")
time.sleep(3)

# Запуск с явным портом через переменную окружения
print("Starting on port 3000...")
run(f"cd {REMOTE_DIR} && PORT=3000 pm2 start 'npm run dev' --name deti-admin")
time.sleep(20)

# Проверка
code = run("curl -s http://127.0.0.1:3000 > /dev/null 2>&1 && echo 'OK' || echo 'FAIL'")
print(f"Check result: {code}")

run("pm2 save")

ssh.close()
print("Done! Check http://168.222.193.86")
