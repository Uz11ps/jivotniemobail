# Команды для выполнения на сервере

Выполните эти команды на сервере для исправления проблемы с портом:

```bash
# 1. Остановите PM2
pm2 delete all

# 2. Убейте все процессы на порту 3000
lsof -ti :3000 | xargs kill -9 2>/dev/null || true
fuser -k 3000/tcp 2>/dev/null || true
pkill -9 -f 'node.*3000' || true
pkill -9 -f 'next.*3000' || true
sleep 3

# 3. Проверьте что порт свободен
lsof -i :3000 || echo "Port 3000 is free"

# 4. Запустите приложение в dev режиме
cd /var/www/168-222-193-86.regru.cloud/data/www/deti-admin
PORT=3000 pm2 start npm --name deti-admin -- run dev

# 5. Сохраните PM2
pm2 save

# 6. Подождите 20 секунд и проверьте
sleep 20
curl http://127.0.0.1:3000

# 7. Проверьте статус
pm2 status
pm2 logs deti-admin --lines 10
```

Или загрузите и выполните скрипт:

```bash
# Загрузите скрипт на сервер
scp server_fix.sh root@168.222.193.86:/tmp/

# На сервере выполните
ssh root@168.222.193.86
chmod +x /tmp/server_fix.sh
/tmp/server_fix.sh
```
