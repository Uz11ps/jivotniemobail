# Настройка админки на сервере с ISPmanager

## Шаг 1: Деплой через скрипт

Запустите скрипт деплоя:

```bash
python deploy_admin_ispmanager.py
```

Скрипт автоматически:
- Установит Node.js и PM2
- Загрузит файлы админки
- Установит зависимости и соберёт проект
- Запустит приложение через PM2

## Шаг 2: Настройка переменных окружения

Подключитесь к серверу:

```bash
ssh root@168.222.193.86
cd /var/www/168-222-193-86.regru.cloud/data/www/deti-admin
nano .env.local
```

Вставьте переменные из Firebase Console:

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

Перезапустите приложение:

```bash
pm2 restart deti-admin
```

## Шаг 3: Настройка проксирования через ISPmanager

### Вариант А: Через веб-интерфейс ISPmanager

1. Войдите в ISPmanager: `http://168.222.193.86:1500` (или ваш порт)
2. Перейдите в раздел **WWW** → **WWW-домены**
3. Найдите или создайте домен `168-222-193-86.regru.cloud`
4. В настройках домена найдите раздел **Дополнительные настройки** или **Nginx**
5. Добавьте следующую конфигурацию в секцию `location /`:

```nginx
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
```

6. Сохраните изменения

### Вариант Б: Через SSH (ручная настройка)

1. Найдите конфигурацию nginx для вашего домена:
```bash
ssh root@168.222.193.86
ls /etc/nginx/conf.d/ | grep 168-222-193-86
```

2. Отредактируйте конфигурацию:
```bash
nano /etc/nginx/conf.d/168-222-193-86.regru.cloud.conf
```

3. Добавьте или замените секцию `location /`:

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

4. Проверьте конфигурацию и перезагрузите nginx:
```bash
nginx -t
systemctl reload nginx
```

## Шаг 4: Проверка работы

1. Проверьте статус PM2:
```bash
pm2 status
pm2 logs deti-admin
```

2. Проверьте доступность приложения:
```bash
curl http://127.0.0.1:3000
```

3. Откройте в браузере:
```
http://168.222.193.86
```

## Настройка домена (опционально)

Если у вас есть домен:

1. В ISPmanager создайте новый WWW-домен с вашим доменом
2. Настройте DNS записи у регистратора:
   - A запись: `168.222.193.86`
3. Настройте проксирование как описано выше
4. Настройте SSL через ISPmanager (Let's Encrypt)

## Управление через PM2

```bash
# Просмотр статуса
pm2 status

# Просмотр логов
pm2 logs deti-admin

# Перезапуск
pm2 restart deti-admin

# Остановка
pm2 stop deti-admin

# Удаление
pm2 delete deti-admin
```

## Обновление админки

После изменений в коде:

```bash
# Запустите скрипт деплоя снова
python deploy_admin_ispmanager.py

# Или вручную на сервере:
ssh root@168.222.193.86
cd /var/www/168-222-193-86.regru.cloud/data/www/deti-admin
# Загрузите новые файлы
npm install
npm run build
pm2 restart deti-admin
```

## Устранение проблем

### Приложение не запускается

1. Проверьте логи:
```bash
pm2 logs deti-admin --lines 50
```

2. Проверьте переменные окружения:
```bash
cd /var/www/168-222-193-86.regru.cloud/data/www/deti-admin
cat .env.local
```

3. Проверьте порт:
```bash
netstat -tlnp | grep 3000
```

### Nginx не проксирует

1. Проверьте конфигурацию nginx:
```bash
nginx -t
```

2. Проверьте логи nginx:
```bash
tail -f /var/log/nginx/error.log
```

3. Убедитесь, что приложение запущено:
```bash
curl http://127.0.0.1:3000
```

### Доступ к ISPmanager

ISPmanager обычно доступен по адресу:
- `http://168.222.193.86:1500` (порт может отличаться)
- Или через SSH: `/usr/local/ispmgr/sbin/mgrctl`

Логин и пароль обычно те же, что и для root SSH.
