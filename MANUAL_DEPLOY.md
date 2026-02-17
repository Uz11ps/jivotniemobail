# Ручной деплой админки на сервер

## Шаг 1: Подключение к серверу

```bash
ssh root@168.222.193.86
# Пароль: tioSvryiHaPKXWMU
```

## Шаг 2: Удаление стандартной страницы ISPmanager

```bash
rm -rf /var/www/168-222-193-86.regru.cloud/data/www/*.html
rm -rf /var/www/168-222-193-86.regru.cloud/data/www/*.php
```

## Шаг 3: Установка Node.js и PM2

```bash
# Проверка Node.js
node --version

# Если не установлен:
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Установка PM2
npm install -g pm2
```

## Шаг 4: Создание директории для админки

```bash
mkdir -p /var/www/168-222-193-86.regru.cloud/data/www/deti-admin
cd /var/www/168-222-193-86.regru.cloud/data/www/deti-admin
```

## Шаг 5: Загрузка файлов админки

**С локальной машины выполните:**

```bash
# Создайте архив
cd admin
tar -czf ../admin.tar.gz --exclude=node_modules --exclude=.next --exclude=.git .

# Загрузите на сервер
scp admin.tar.gz root@168.222.193.86:/tmp/

# На сервере распакуйте
ssh root@168.222.193.86
cd /var/www/168-222-193-86.regru.cloud/data/www/deti-admin
tar -xzf /tmp/admin.tar.gz
rm /tmp/admin.tar.gz
```

**Или используйте git (если настроен):**

```bash
cd /var/www/168-222-193-86.regru.cloud/data/www/deti-admin
git clone <ваш_репозиторий> .
```

## Шаг 6: Установка зависимостей и сборка

```bash
cd /var/www/168-222-193-86.regru.cloud/data/www/deti-admin
npm install
npm run build
```

## Шаг 7: Настройка переменных окружения

```bash
nano .env.local
```

Вставьте:

```env
NEXT_PUBLIC_FIREBASE_API_KEY=ваш_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=ваш_проект.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=ваш_проект_id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=ваш_проект.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=ваш_sender_id
NEXT_PUBLIC_FIREBASE_APP_ID=ваш_app_id

FIREBASE_PROJECT_ID=ваш_проект_id
FIREBASE_CLIENT_EMAIL=ваш_service_account_email
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

Сохраните: `Ctrl+O`, `Enter`, `Ctrl+X`

## Шаг 8: Запуск через PM2

```bash
cd /var/www/168-222-193-86.regru.cloud/data/www/deti-admin
pm2 delete deti-admin 2>/dev/null || true
pm2 start npm --name deti-admin -- start
pm2 save
pm2 startup
```

## Шаг 9: Настройка nginx

### Вариант А: Через ISPmanager веб-интерфейс

1. Откройте `http://168.222.193.86:1500` (или ваш порт ISPmanager)
2. WWW → WWW-домены → `168-222-193-86.regru.cloud`
3. В дополнительных настройках nginx добавьте:

```nginx
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
```

### Вариант Б: Через SSH

```bash
nano /etc/nginx/conf.d/168-222-193-86.regru.cloud.conf
```

Вставьте:

```nginx
server {
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
```

Проверьте и перезагрузите:

```bash
nginx -t
systemctl reload nginx
```

## Шаг 10: Проверка

```bash
# Проверка PM2
pm2 status
pm2 logs deti-admin

# Проверка порта
curl http://127.0.0.1:3000

# Откройте в браузере
# http://168.222.193.86
```

## Быстрые команды

```bash
# Перезапуск админки
pm2 restart deti-admin

# Просмотр логов
pm2 logs deti-admin --lines 50

# Обновление после изменений
cd /var/www/168-222-193-86.regru.cloud/data/www/deti-admin
npm install
npm run build
pm2 restart deti-admin
```
