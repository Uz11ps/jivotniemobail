"""Исправление конфигурации nginx для правильного проксирования"""
import paramiko

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
    print(f"[{code}] {c}")
    if err and code != 0:
        print(f"  ERR: {err[:300]}")
    return code, out

print("Исправление конфигурации nginx...")

# Находим конфигурацию сайта
print("\n1. Поиск конфигурации nginx...")
code, out = cmd("find /etc/nginx -type f -name '*168-222-193-86*' -o -name '*regru*' 2>/dev/null | grep -v '.bak' | head -5")
print(f"Найдено: {out}")

# Проверяем структуру vhosts в ISPmanager
code, out = cmd("ls -la /etc/nginx/vhosts-resources/ 2>/dev/null | head -10")
print(f"\nvhosts-resources: {out[:500]}")

# Ищем основной конфиг сайта
code, out = cmd("find /etc/nginx -type f -name '*.conf' | xargs grep -l '168-222-193-86' 2>/dev/null | head -3")
config_files = out.strip().split('\n') if out.strip() else []

if not config_files or config_files == ['']:
    # Пробуем найти через ISPmanager структуру
    code, out = cmd("ls /etc/nginx/vhosts-resources/168-222-193-86.regru.cloud/ 2>/dev/null")
    if code == 0:
        print("Найдена директория vhosts-resources")
        # ISPmanager использует другую структуру
        main_config = "/etc/nginx/vhosts/168-222-193-86.regru.cloud.conf"
    else:
        main_config = "/etc/nginx/conf.d/168-222-193-86.regru.cloud.conf"
else:
    main_config = config_files[0].strip()

print(f"\n2. Работаем с конфигом: {main_config}")

# Читаем текущий конфиг
code, current_config = cmd(f"cat {main_config} 2>/dev/null || echo 'NOT_FOUND'")
print(f"\nТекущий конфиг:\n{current_config[:1000]}")

# Создаем правильную конфигурацию
nginx_config = """server {
    listen 80;
    server_name 168-222-193-86.regru.cloud;

    # Удаляем стандартную страницу
    root /var/www/168-222-193-86.regru.cloud/data/www;
    index index.html index.php;

    # Проксирование на Next.js приложение
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

# Сохраняем новый конфиг
print("\n3. Создание новой конфигурации...")
sftp = ssh.open_sftp()
tmp_path = "/tmp/nginx-fix.conf"
with sftp.open(tmp_path, "w") as f:
    f.write(nginx_config)
sftp.close()

# Бэкап старого конфига
cmd(f"cp {main_config} {main_config}.bak 2>/dev/null || true")

# Копируем новый конфиг
cmd(f"cp {tmp_path} {main_config}")

# Проверяем конфигурацию
print("\n4. Проверка конфигурации nginx...")
code, out = cmd("nginx -t")
if code == 0:
    print("[OK] Конфигурация валидна!")
    # Перезагружаем nginx
    print("\n5. Перезагрузка nginx...")
    cmd("systemctl reload nginx 2>/dev/null || service nginx reload")
    print("[OK] Nginx перезагружен!")
else:
    print(f"[ERROR] Ошибка в конфигурации: {out}")
    # Восстанавливаем бэкап
    cmd(f"cp {main_config}.bak {main_config}")

# Проверяем приложение
print("\n6. Проверка приложения...")
code, out = cmd("pm2 status")
print(out[:500])

code, out = cmd("curl -s http://127.0.0.1:3000 2>&1 | head -3")
if "Next.js" in out or "200" in str(code):
    print("[OK] Приложение работает!")
else:
    print("[WARN] Приложение может не работать, проверьте: pm2 logs deti-admin")

# Финальная проверка
print("\n7. Финальная проверка...")
code, out = cmd("curl -s -I http://127.0.0.1/ 2>&1 | head -5")
print(out[:300])

ssh.close()
print("\nГотово! Проверьте: http://168.222.193.86")
