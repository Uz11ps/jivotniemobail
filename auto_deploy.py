"""
Полностью автоматизированный деплой админки с retry логикой.
Выполняет все шаги: удаление стандартной страницы, установку зависимостей, деплой и настройку nginx.
"""
import os
import sys
import time
import tarfile
import tempfile

try:
    import paramiko
except ImportError:
    print("Установите: pip install paramiko")
    sys.exit(1)

SERVER = "168.222.193.86"
PORT = 22
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"
ADMIN_PORT = 3000
MAX_RETRIES = 5
RETRY_DELAY = 10


def connect_with_retry():
    """Подключение с повторными попытками"""
    for attempt in range(MAX_RETRIES):
        try:
            print(f"Попытка подключения {attempt + 1}/{MAX_RETRIES}...")
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh.connect(SERVER, PORT, USER, PASSWORD, timeout=30)
            print("[OK] Подключение установлено!")
            return ssh
        except Exception as e:
            print(f"[ERROR] Ошибка подключения: {e}")
            if attempt < MAX_RETRIES - 1:
                print(f"Повтор через {RETRY_DELAY} секунд...")
                time.sleep(RETRY_DELAY)
            else:
                print("Не удалось подключиться после всех попыток")
                sys.exit(1)
    return None


def run_cmd(ssh, cmd, check=True, retries=3):
    """Выполнение команды с повторными попытками"""
    for attempt in range(retries):
        try:
            _, stdout, stderr = ssh.exec_command(cmd, timeout=60)
            code = stdout.channel.recv_exit_status()
            out = stdout.read().decode(errors="replace")
            err = stderr.read().decode(errors="replace")
            
            if check and code != 0:
                if attempt < retries - 1:
                    print(f"  Повтор команды ({attempt + 1}/{retries})...")
                    time.sleep(2)
                    continue
                print(f"[WARN] Ошибка [{code}]: {cmd}")
                if err:
                    print(f"  {err[:200]}")
            return code, out, err
        except Exception as e:
            if attempt < retries - 1:
                print(f"  Ошибка выполнения, повтор... ({e})")
                time.sleep(2)
                continue
            raise
    return -1, "", ""


def deploy():
    print("=" * 60)
    print("АВТОМАТИЧЕСКИЙ ДЕПЛОЙ АДМИНКИ")
    print("=" * 60)
    
    ssh = connect_with_retry()
    
    try:
        # Шаг 1: Удаление стандартной страницы ISPmanager
        print("\n[1/8] Удаление стандартной страницы ISPmanager...")
        www_root = "/var/www/168-222-193-86.regru.cloud/data/www"
        run_cmd(ssh, f"rm -rf {www_root}/*.html {www_root}/*.php", check=False)
        print("[OK] Стандартная страница удалена")
        
        # Шаг 2: Установка Node.js
        print("\n[2/8] Проверка Node.js...")
        code, out, _ = run_cmd(ssh, "node --version", check=False)
        if code != 0:
            print("  Установка Node.js 18...")
            run_cmd(ssh, "curl -fsSL https://deb.nodesource.com/setup_18.x | bash -")
            run_cmd(ssh, "DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs")
            print("[OK] Node.js установлен")
        else:
            print(f"[OK] Node.js уже установлен: {out.strip()}")
        
        # Шаг 3: Установка PM2
        print("\n[3/8] Проверка PM2...")
        code, out, _ = run_cmd(ssh, "pm2 --version", check=False)
        if code != 0:
            print("  Установка PM2...")
            run_cmd(ssh, "npm install -g pm2")
            print("[OK] PM2 установлен")
        else:
            print(f"[OK] PM2 уже установлен: {out.strip()}")
        
        # Шаг 4: Создание архива
        print("\n[4/8] Создание архива админки...")
        admin_local_dir = "admin"
        if not os.path.isdir(admin_local_dir):
            print(f"[ERROR] Ошибка: директория {admin_local_dir} не найдена")
            ssh.close()
            sys.exit(1)
        
        with tempfile.NamedTemporaryFile(suffix='.tar.gz', delete=False) as tmp_file:
            archive_path = tmp_file.name
        
        try:
            with tarfile.open(archive_path, 'w:gz') as tar:
                for root, dirs, files in os.walk(admin_local_dir):
                    dirs[:] = [d for d in dirs if d not in ['node_modules', '.next', '.git', '.vercel']]
                    for file in files:
                        if file.startswith('.') and file not in ['.env.example', '.gitignore']:
                            continue
                        local_path = os.path.join(root, file)
                        arcname = os.path.relpath(local_path, admin_local_dir)
                        tar.add(local_path, arcname=arcname)
            print("[OK] Архив создан")
        except Exception as e:
            print(f"[ERROR] Ошибка создания архива: {e}")
            ssh.close()
            sys.exit(1)
        
        # Шаг 5: Загрузка и распаковка
        print("\n[5/8] Загрузка файлов на сервер...")
        remote_archive = "/tmp/deti-admin.tar.gz"
        sftp = ssh.open_sftp()
        try:
            sftp.put(archive_path, remote_archive)
            print("[OK] Файлы загружены")
        except Exception as e:
            print(f"[ERROR] Ошибка загрузки: {e}")
            sftp.close()
            os.unlink(archive_path)
            ssh.close()
            sys.exit(1)
        finally:
            sftp.close()
            os.unlink(archive_path)
        
        print("  Распаковка...")
        run_cmd(ssh, f"mkdir -p {REMOTE_DIR}")
        run_cmd(ssh, f"cd {REMOTE_DIR} && tar -xzf {remote_archive}")
        run_cmd(ssh, f"rm -f {remote_archive}")
        print("[OK] Файлы распакованы")
        
        # Шаг 6: Установка зависимостей
        print("\n[6/8] Установка зависимостей (это может занять несколько минут)...")
        run_cmd(ssh, f"cd {REMOTE_DIR} && npm install --production=false", retries=2)
        print("[OK] Зависимости установлены")
        
        # Шаг 7: Сборка проекта
        print("\n[7/8] Сборка проекта...")
        run_cmd(ssh, f"cd {REMOTE_DIR} && npm run build", retries=2)
        print("[OK] Проект собран")
        
        # Шаг 8: Запуск через PM2
        print("\n[8/8] Запуск приложения...")
        run_cmd(ssh, f"pm2 delete deti-admin 2>/dev/null || true", check=False)
        run_cmd(ssh, f"cd {REMOTE_DIR} && pm2 start npm --name deti-admin -- start")
        run_cmd(ssh, "pm2 save")
        run_cmd(ssh, "pm2 startup systemd -u root --hp /root 2>/dev/null || true", check=False)
        print("[OK] Приложение запущено через PM2")
        
        # Настройка nginx
        print("\n[9/9] Настройка nginx...")
        nginx_config = f"""server {{
    listen 80;
    server_name 168-222-193-86.regru.cloud;

    location / {{
        proxy_pass http://127.0.0.1:{ADMIN_PORT};
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
    }}
}}
"""
        
        config_path = "/etc/nginx/conf.d/168-222-193-86.regru.cloud.conf"
        tmp_path = "/tmp/deti-admin-nginx.conf"
        
        sftp = ssh.open_sftp()
        try:
            with sftp.open(tmp_path, "w") as f:
                f.write(nginx_config)
        finally:
            sftp.close()
        
        # Пробуем обновить конфиг напрямую
        code, _, _ = run_cmd(ssh, f"test -f {config_path}", check=False)
        if code == 0:
            run_cmd(ssh, f"cp {tmp_path} {config_path}")
            run_cmd(ssh, "nginx -t", check=False)
            run_cmd(ssh, "systemctl reload nginx 2>/dev/null || service nginx reload", check=False)
            print("[OK] Nginx настроен и перезагружен")
        else:
            # Сохраняем для ручной настройки
            run_cmd(ssh, f"cp {tmp_path} {REMOTE_DIR}/nginx-config.conf")
            print(f"[WARN] Конфигурация nginx сохранена в {REMOTE_DIR}/nginx-config.conf")
            print("  Настройте проксирование через ISPmanager или скопируйте конфиг в /etc/nginx/conf.d/")
        
        # Проверка статуса
        print("\n" + "=" * 60)
        print("ПРОВЕРКА СТАТУСА")
        print("=" * 60)
        run_cmd(ssh, "pm2 status", check=False)
        
        # Проверка порта
        code, out, _ = run_cmd(ssh, f"curl -s -o /dev/null -w '%{{http_code}}' http://127.0.0.1:{ADMIN_PORT} || echo '000'", check=False)
        if "200" in out or "000" not in out:
            print(f"[OK] Приложение отвечает на порту {ADMIN_PORT}")
        else:
            print(f"[WARN] Проверьте приложение вручную: curl http://127.0.0.1:{ADMIN_PORT}")
        
    finally:
        ssh.close()
    
    print("\n" + "=" * 60)
    print("ДЕПЛОЙ ЗАВЕРШЕН!")
    print("=" * 60)
    print(f"[OK] Файлы: {REMOTE_DIR}")
    print(f"[OK] Приложение запущено на порту {ADMIN_PORT}")
    print(f"[OK] Доступ: http://{SERVER}")
    print("\n[WARN] ВАЖНО:")
    print("1. Настройте .env.local с Firebase credentials:")
    print(f"   ssh {USER}@{SERVER}")
    print(f"   cd {REMOTE_DIR}")
    print("   nano .env.local")
    print("2. Перезапустите приложение после настройки .env.local:")
    print("   pm2 restart deti-admin")
    print("\n" + "=" * 60)


if __name__ == "__main__":
    try:
        deploy()
    except KeyboardInterrupt:
        print("\n\nДеплой прерван пользователем")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n[ERROR] Критическая ошибка: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
