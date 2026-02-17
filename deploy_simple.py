"""Упрощенный скрипт деплоя"""
import paramiko
import os

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
print("Подключение...")
ssh.connect(SERVER, 22, USER, PASSWORD)

def cmd(c):
    _, stdout, stderr = ssh.exec_command(c)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace")
    err = stderr.read().decode(errors="replace")
    print(f"[{code}] {c}")
    if code != 0 and err:
        print(f"  ERR: {err[:200]}")
    return code, out, err

# Удаление стандартной страницы
print("\n1. Удаление стандартной страницы ISPmanager...")
cmd("rm -rf /var/www/168-222-193-86.regru.cloud/data/www/*.html")
cmd("rm -rf /var/www/168-222-193-86.regru.cloud/data/www/*.php")

# Node.js
print("\n2. Проверка Node.js...")
code, _, _ = cmd("node --version")
if code != 0:
    print("  Установка Node.js...")
    cmd("curl -fsSL https://deb.nodesource.com/setup_18.x | bash -")
    cmd("apt-get install -y nodejs")

# PM2
print("\n3. Проверка PM2...")
code, _, _ = cmd("pm2 --version")
if code != 0:
    print("  Установка PM2...")
    cmd("npm install -g pm2")

# Загрузка файлов через scp
print("\n4. Загрузка файлов...")
print("  Используйте: scp -r admin/* root@168.222.193.86:" + REMOTE_DIR + "/")
print("  Или запустите полный скрипт deploy_admin_ispmanager.py")

ssh.close()
print("\nГотово! Загрузите файлы вручную или используйте полный скрипт.")
