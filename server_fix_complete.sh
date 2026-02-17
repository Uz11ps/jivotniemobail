#!/bin/bash
# Полное исправление на сервере

echo "=== Complete Fix ==="

# 1. Полная остановка
echo "[1] Stopping everything..."
pm2 delete all 2>/dev/null || true
pm2 kill 2>/dev/null || true
pkill -9 node 2>/dev/null || true
pkill -9 npm 2>/dev/null || true
pkill -9 next 2>/dev/null || true
sleep 3

# 2. Освобождение порта
echo "[2] Freeing port 3000..."
fuser -k 3000/tcp 2>/dev/null || true
lsof -ti :3000 | xargs kill -9 2>/dev/null || true
ss -K dst :3000 2>/dev/null || true
sleep 3

# 3. Проверка порта
echo "[3] Checking port..."
if lsof -i :3000 > /dev/null 2>&1; then
    echo "ERROR: Port 3000 still busy!"
    lsof -i :3000
    exit 1
else
    echo "OK: Port 3000 is free"
fi

# 4. Переход в директорию
cd /var/www/168-222-193-86.regru.cloud/data/www/deti-admin || exit 1

# 5. Проверка .env.local
echo "[4] Checking .env.local..."
if [ ! -f .env.local ]; then
    echo "Creating minimal .env.local..."
    cat > .env.local << EOF
NEXT_PUBLIC_FIREBASE_API_KEY=placeholder
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=placeholder.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=placeholder
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=placeholder.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=123456789
NEXT_PUBLIC_FIREBASE_APP_ID=1:123456789:web:abc123
EOF
fi

# 6. Запуск через PM2 с правильными переменными
echo "[5] Starting application..."
PORT=3000 NODE_ENV=development pm2 start npm --name deti-admin -- run dev

# 7. Сохранение
pm2 save

# 8. Ожидание
echo "[6] Waiting 30 seconds for startup..."
sleep 30

# 9. Проверка
echo "[7] Checking application..."
for i in {1..10}; do
    if curl -s http://127.0.0.1:3000 > /dev/null 2>&1; then
        echo "OK: Application is working! (attempt $i)"
        curl -s http://127.0.0.1:3000 | head -5
        break
    else
        echo "Attempt $i/10... waiting 3 seconds"
        sleep 3
    fi
done

# 10. Статус
echo ""
echo "[8] PM2 Status:"
pm2 list

echo ""
echo "[9] Recent logs:"
pm2 logs deti-admin --lines 10 --nostream 2>&1 | tail -20

echo ""
echo "=== Done ==="
echo "Check: http://168.222.193.86"
