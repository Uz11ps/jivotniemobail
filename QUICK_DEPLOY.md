# Быстрый деплой админки

## Для сервера с ISPmanager

Используйте специальный скрипт:

```bash
python deploy_admin_ispmanager.py
```

См. подробную инструкцию: [docs/ISPmanager_SETUP.md](docs/ISPmanager_SETUP.md)

## Для обычного сервера

Запустите оптимизированный скрипт:

```bash
python deploy_admin_fast.py
```

Скрипт автоматически:
1. Подключится к серверу
2. Установит Node.js и PM2 (если нужно)
3. Заархивирует и загрузит файлы админки
4. Установит зависимости
5. Соберёт проект
6. Запустит через PM2
7. Настроит nginx

## Настройка переменных окружения на сервере

После деплоя подключитесь к серверу и создайте `.env.local`:

```bash
ssh root@168.222.193.86
cd /root/deti-admin
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

После сохранения перезапустите приложение:

```bash
pm2 restart deti-admin
```

## Проверка работы

```bash
# Проверка статуса
pm2 status

# Просмотр логов
pm2 logs deti-admin

# Проверка порта
curl http://127.0.0.1:3000
```

## Обновление после изменений

Просто запустите скрипт деплоя снова:

```bash
python deploy_admin_fast.py
```

Или вручную на сервере:

```bash
ssh root@168.222.193.86
cd /root/deti-admin
# Загрузите новые файлы или сделайте git pull
npm install
npm run build
pm2 restart deti-admin
```
