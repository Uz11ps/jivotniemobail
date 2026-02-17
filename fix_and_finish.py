"""Исправление ошибки сборки и завершение настройки"""
import paramiko

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
print("Подключение...")
ssh.connect(SERVER, 22, USER, PASSWORD)

def cmd(c):
    _, stdout, stderr = ssh.exec_command(c, timeout=120)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    print(f"[{code}] {c}")
    if out and len(out.strip()) > 0:
        try:
            print(f"  OUT: {out[:200]}")
        except:
            pass
    if err and code != 0 and len(err.strip()) > 0:
        try:
            print(f"  ERR: {err[:200]}")
        except:
            pass
    return code, out, err

print("\n1. Очистка и пересборка...")
cmd(f"cd {REMOTE_DIR} && rm -rf .next node_modules/.cache")
cmd(f"cd {REMOTE_DIR} && NODE_OPTIONS='--max-old-space-size=2048' npm run build")

print("\n2. Перезапуск PM2...")
cmd("pm2 restart deti-admin")
cmd("pm2 status")

print("\n3. Настройка nginx...")
nginx_config = """server {
    listen 80;
    server_name 168-222-193-86.regru.cloud;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
"""

sftp = ssh.open_sftp()
tmp_path = "/tmp/deti-admin-nginx.conf"
with sftp.open(tmp_path, "w") as f:
    f.write(nginx_config)
sftp.close()

# Пробуем найти существующий конфиг
code, _, _ = cmd("find /etc/nginx -name '*168-222-193-86*' -o -name '*regru*' 2>/dev/null | head -1")
if code == 0:
    config_path = "/etc/nginx/conf.d/168-222-193-86.regru.cloud.conf"
    cmd(f"cp {tmp_path} {config_path}")
    cmd("nginx -t")
    cmd("systemctl reload nginx 2>/dev/null || service nginx reload")
    print("[OK] Nginx настроен!")
else:
    cmd(f"cp {tmp_path} {REMOTE_DIR}/nginx-config.conf")
    print(f"[WARN] Конфиг сохранен в {REMOTE_DIR}/nginx-config.conf")

print("\n4. Проверка приложения...")
code, out, _ = cmd("curl -s http://127.0.0.1:3000 | head -20")
if code == 0 and out:
    print("[OK] Приложение работает!")
else:
    print("[WARN] Проверьте логи: pm2 logs deti-admin")

ssh.close()
print("\nГотово!")
