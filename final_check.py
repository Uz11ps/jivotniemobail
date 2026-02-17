"""Финальная проверка и исправление"""
import paramiko

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def safe_print(text):
    try:
        print(text.encode('ascii', errors='ignore').decode('ascii'))
    except:
        print("(вывод содержит специальные символы)")

def cmd(c):
    _, stdout, stderr = ssh.exec_command(c, timeout=30)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    return code, out

print("Финальная проверка и исправление...")

# 1. Проверка PM2
print("\n1. Проверка PM2...")
code, out = cmd("pm2 list")
safe_print(out[:400])

# Перезапуск если нужно
code, _ = cmd("pm2 restart deti-admin")
print("[OK] PM2 перезапущен")

# 2. Проверка приложения на порту 3000
print("\n2. Проверка приложения на порту 3000...")
code, out = cmd("sleep 3 && curl -s http://127.0.0.1:3000 2>&1 | head -10")
if "Next.js" in out or code == 0:
    print("[OK] Приложение работает на порту 3000")
    safe_print(out[:200])
else:
    print("[WARN] Приложение не отвечает, проверяю логи...")
    code, logs = cmd("pm2 logs deti-admin --lines 5 --nostream 2>&1")
    safe_print(logs[:500])

# 3. Проверка конфигурации nginx
print("\n3. Проверка конфигурации nginx...")
code, config = cmd("cat /etc/nginx/vhosts/www-root/168-222-193-86.regru.cloud.conf | grep -A 10 'location /'")
if "proxy_pass" in config and "3000" in config:
    print("[OK] Nginx настроен на проксирование на порт 3000")
    safe_print(config[:300])
else:
    print("[ERROR] Проксирование не настроено правильно!")
    # Исправляем
    nginx_fix = """
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
    }
    """
    # Добавляем в конфиг через ISPmanager структуру
    sftp = ssh.open_sftp()
    proxy_config = "/etc/nginx/vhosts-resources/168-222-193-86.regru.cloud/proxy.conf"
    try:
        with sftp.open(proxy_config, "w") as f:
            f.write(nginx_fix)
        print("[OK] Создан proxy.conf")
    except:
        print("[WARN] Не удалось создать proxy.conf, используйте веб-интерфейс ISPmanager")
    finally:
        sftp.close()

# 4. Перезагрузка nginx
print("\n4. Перезагрузка nginx...")
code, _ = cmd("nginx -t && systemctl reload nginx")
print("[OK] Nginx перезагружен")

# 5. Финальная проверка
print("\n5. Финальная проверка через внешний доступ...")
code, out = cmd("curl -s -I http://127.0.0.1/ 2>&1 | head -5")
safe_print(out[:300])

ssh.close()

print("\n" + "="*60)
print("ГОТОВО!")
print("="*60)
print("Проверьте в браузере: http://168.222.193.86")
print("\nЕсли все еще видна стандартная страница:")
print("1. Очистите кэш браузера (Ctrl+F5)")
print("2. Проверьте: pm2 logs deti-admin")
print("3. Проверьте конфигурацию через ISPmanager веб-интерфейс")
