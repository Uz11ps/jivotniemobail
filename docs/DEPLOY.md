# Инструкция по деплою

## Деплой админ-панели на сервер

### Предварительные требования

1. Установите зависимости для скрипта деплоя:
```bash
pip install paramiko scp
```

2. Настройте переменные окружения (опционально):
```bash
export DEPLOY_HOST=168.222.193.86
export DEPLOY_USER=root
export DEPLOY_PASSWORD=tioSvryiHaPKXWMU
```

### Шаги деплоя

1. **Подготовьте файл .env.local** в папке `admin/`:
   - Скопируйте `.env.example` в `.env.local`
   - Заполните все переменные окружения из Firebase Console

2. **Запустите скрипт деплоя**:
```bash
python deploy_admin.py
```

Скрипт автоматически:
- Проверит и установит Node.js 18 (если нужно)
- Установит PM2 (если нужно)
- Загрузит файлы админки на сервер
- Установит зависимости (`npm install`)
- Соберёт проект (`npm run build`)
- Запустит через PM2
- Настроит nginx для проксирования

### Ручной деплой (если скрипт не работает)

1. **Подключитесь к серверу**:
```bash
ssh root@168.222.193.86
```

2. **Установите Node.js и PM2**:
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
npm install -g pm2
```

3. **Создайте директорию**:
```bash
mkdir -p /root/deti-admin
cd /root/deti-admin
```

4. **Загрузите файлы** (через scp или git):
```bash
# Через scp с локальной машины:
scp -r admin/* root@168.222.193.86:/root/deti-admin/
```

5. **Установите зависимости и соберите**:
```bash
cd /root/deti-admin
npm install
npm run build
```

6. **Создайте .env.local**:
```bash
nano .env.local
# Вставьте переменные окружения
```

7. **Запустите через PM2**:
```bash
pm2 start npm --name deti-admin -- start
pm2 save
pm2 startup
```

8. **Настройте nginx**:
```bash
nano /etc/nginx/sites-available/deti-admin.conf
```

Вставьте конфигурацию:
```nginx
server {
    listen 80;
    server_name admin.detizhivotnie.ru;

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
}
```

Активируйте конфигурацию:
```bash
ln -s /etc/nginx/sites-available/deti-admin.conf /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

## Деплой Firebase

### Автоматический деплой

```bash
chmod +x deploy_firebase.sh
./deploy_firebase.sh
```

### Ручной деплой

```bash
cd firebase
npm install
npm run build
firebase deploy --only firestore:rules,firestore:indexes,storage:rules,functions
```

## Обновление админки

После изменений в коде:

1. **Локально**:
```bash
cd admin
# Внесите изменения
```

2. **Запустите деплой**:
```bash
python deploy_admin.py
```

Или вручную на сервере:
```bash
ssh root@168.222.193.86
cd /root/deti-admin
git pull  # если используете git
# или загрузите файлы через scp
npm install
npm run build
pm2 restart deti-admin
```

## Проверка статуса

### На сервере:
```bash
pm2 status
pm2 logs deti-admin
```

### Проверка nginx:
```bash
nginx -t
systemctl status nginx
```

### Проверка портов:
```bash
netstat -tlnp | grep 3000
```

## Устранение проблем

### Приложение не запускается

1. Проверьте логи PM2:
```bash
pm2 logs deti-admin --lines 50
```

2. Проверьте переменные окружения:
```bash
cd /root/deti-admin
cat .env.local
```

3. Проверьте порт:
```bash
lsof -i :3000
```

### Nginx не проксирует

1. Проверьте конфигурацию:
```bash
nginx -t
```

2. Проверьте логи:
```bash
tail -f /var/log/nginx/error.log
```

3. Убедитесь, что приложение запущено:
```bash
curl http://127.0.0.1:3000
```

### Ошибки сборки

1. Очистите кэш:
```bash
cd /root/deti-admin
rm -rf .next node_modules
npm install
npm run build
```

## Настройка домена

1. Настройте DNS записи для домена `admin.detizhivotnie.ru`:
   - A запись: `168.222.193.86`

2. Обновите nginx конфигурацию с правильным доменом

3. Настройте SSL сертификат (Let's Encrypt):
```bash
apt-get install certbot python3-certbot-nginx
certbot --nginx -d admin.detizhivotnie.ru
```

## Мониторинг

### PM2 мониторинг:
```bash
pm2 monit
```

### Логи в реальном времени:
```bash
pm2 logs deti-admin --lines 100
```

### Перезапуск приложения:
```bash
pm2 restart deti-admin
```
