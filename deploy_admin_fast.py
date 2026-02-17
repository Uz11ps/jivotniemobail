"""
Оптимизированный скрипт деплоя админ-панели на сервер.
Использует tar для быстрой передачи файлов.
"""
import os
import sys
import tarfile
import tempfile

try:
    import paramiko
except ImportError:
    print("Установите: pip install paramiko")
    sys.exit(1)

SERVER = os.getenv("DEPLOY_HOST", "168.222.193.86")
PORT = int(os.getenv("DEPLOY_PORT", "22"))
USER = os.getenv("DEPLOY_USER", "root")
PASSWORD = os.getenv("DEPLOY_PASSWORD", "tioSvryiHaPKXWMU")
REMOTE_DIR = "/root/deti-admin"
ADMIN_PORT = 3000


def deploy():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print(f"Подключение к {SERVER}...")
    ssh.connect(SERVER, PORT, USER, PASSWORD)

    def run(cmd: str, check: bool = True) -> tuple[int, str, str]:
        _, stdout, stderr = ssh.exec_command(cmd)
        code = stdout.channel.recv_exit_status()
        out = stdout.read().decode(errors="replace")
        err = stderr.read().decode(errors="replace")
        if check and code != 0:
            print(f"Ошибка [{code}]: {cmd}\n{err or out}")
        return code, out, err

    # Проверка Node.js
    code, node_version, _ = run("node --version", check=False)
    if code != 0:
        print("Node.js не установлен. Установка Node.js 18...")
        run("curl -fsSL https://deb.nodesource.com/setup_18.x | bash -")
        run("apt-get install -y nodejs")
    else:
        print(f"Node.js установлен: {node_version.strip()}")

    # Проверка PM2
    code, pm2_version, _ = run("pm2 --version", check=False)
    if code != 0:
        print("PM2 не установлен. Установка PM2...")
        run("npm install -g pm2")
    else:
        print(f"PM2 установлен: {pm2_version.strip()}")

    # Создание архива
    print("Создание архива...")
    admin_local_dir = "admin"
    if not os.path.isdir(admin_local_dir):
        print(f"Ошибка: директория {admin_local_dir} не найдена")
        ssh.close()
        sys.exit(1)

    with tempfile.NamedTemporaryFile(suffix='.tar.gz', delete=False) as tmp_file:
        archive_path = tmp_file.name

    try:
        with tarfile.open(archive_path, 'w:gz') as tar:
            for root, dirs, files in os.walk(admin_local_dir):
                # Пропускаем ненужные директории
                dirs[:] = [d for d in dirs if d not in ['node_modules', '.next', '.git', '.vercel']]
                
                for file in files:
                    if file.startswith('.') and file != '.env.example':
                        continue
                    local_path = os.path.join(root, file)
                    arcname = os.path.relpath(local_path, admin_local_dir)
                    tar.add(local_path, arcname=arcname)

        # Загрузка архива
        print("Загрузка архива на сервер...")
        sftp = ssh.open_sftp()
        remote_archive = "/tmp/deti-admin.tar.gz"
        sftp.put(archive_path, remote_archive)
        sftp.close()

        # Распаковка на сервере
        print("Распаковка на сервере...")
        run(f"mkdir -p {REMOTE_DIR}")
        run(f"cd {REMOTE_DIR} && tar -xzf {remote_archive}")
        run(f"rm -f {remote_archive}")

    finally:
        os.unlink(archive_path)

    # Загрузка .env.local если существует
    local_env = os.path.join(admin_local_dir, ".env.local")
    if os.path.isfile(local_env):
        print("Загрузка .env.local...")
        sftp = ssh.open_sftp()
        sftp.put(local_env, f"{REMOTE_DIR}/.env.local")
        sftp.close()
    else:
        print("Предупреждение: .env.local не найден.")
        print("Создайте его на сервере или используйте .env.example как основу.")

    # Установка зависимостей
    print("Установка зависимостей...")
    run(f"cd {REMOTE_DIR} && npm install --production=false")

    # Сборка проекта
    print("Сборка проекта...")
    run(f"cd {REMOTE_DIR} && npm run build")

    # Остановка старого процесса PM2 если есть
    run(f"pm2 delete deti-admin 2>/dev/null || true", check=False)

    # Запуск через PM2
    print("Запуск приложения через PM2...")
    run(f"cd {REMOTE_DIR} && pm2 start npm --name deti-admin -- start")
    run("pm2 save")
    run("pm2 startup systemd -u root --hp /root 2>/dev/null || true", check=False)

    # Настройка nginx
    nginx_config = f"""server {{
    listen 80;
    server_name admin.detizhivotnie.ru;

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
    
    print("Настройка nginx...")
    code, _, _ = run("which nginx", check=False)
    if code == 0:
        tmp_path = "/tmp/deti-admin.conf"
        sftp = ssh.open_sftp()
        try:
            with sftp.open(tmp_path, "w") as f:
                f.write(nginx_config)
        finally:
            sftp.close()
        run(f"cp {tmp_path} /etc/nginx/sites-available/deti-admin.conf")
        run(f"ln -sf /etc/nginx/sites-available/deti-admin.conf /etc/nginx/sites-enabled/deti-admin.conf")
        run("nginx -t")
        run("systemctl reload nginx 2>/dev/null || service nginx reload")
        print("Nginx настроен.")
    else:
        print("Nginx не найден. Настройте прокси вручную.")

    # Проверка статуса
    print("\nПроверка статуса PM2...")
    run("pm2 status")

    ssh.close()
    print("\nДеплой завершен!")
    print(f"Админка доступна по адресу: http://{SERVER}")
    print("PM2 процессы:")
    print("  - deti-admin (порт 3000)")
    print("\nВажно: Убедитесь, что .env.local настроен на сервере!")


if __name__ == "__main__":
    deploy()
