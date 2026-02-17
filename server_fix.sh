#!/bin/bash
# Скрипт для выполнения на сервере для исправления проблемы

echo "Fixing port conflict..."

# Остановка PM2
pm2 delete all
sleep 2

# Убиваем все процессы на порту 3000
echo "Killing processes on port 3000..."
lsof -ti :3000 | xargs kill -9 2>/dev/null || true
fuser -k 3000/tcp 2>/dev/null || true
pkill -9 -f 'node.*3000' || true
pkill -9 -f 'next.*3000' || true
pkill -9 -f 'npm.*dev' || true
sleep 3

# Проверка что порт свободен
if lsof -i :3000 > /dev/null 2>&1; then
    echo "Port 3000 still busy, trying fuser..."
    fuser -k 3000/tcp 2>/dev/null || true
    sleep 2
fi

# Запуск в dev режиме
echo "Starting application..."
cd /var/www/168-222-193-86.regru.cloud/data/www/deti-admin
PORT=3000 pm2 start npm --name deti-admin -- run dev

# Сохранение
pm2 save

echo ""
echo "Waiting 20 seconds for startup..."
sleep 20

# Проверка
echo ""
echo "Checking application..."
curl -s http://127.0.0.1:3000 > /dev/null 2>&1 && echo "OK - Application is working!" || echo "WARN - Check logs: pm2 logs deti-admin"

echo ""
echo "PM2 status:"
pm2 list

echo ""
echo "Done! Check http://168.222.193.86"
