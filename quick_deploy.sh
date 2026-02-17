#!/bin/bash
# Быстрый скрипт для загрузки файлов на сервер

SERVER="168.222.193.86"
USER="root"
REMOTE_DIR="/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

echo "Создание архива админки..."
cd admin
tar -czf ../admin.tar.gz --exclude=node_modules --exclude=.next --exclude=.git --exclude='.env.local' .
cd ..

echo "Загрузка на сервер..."
scp admin.tar.gz ${USER}@${SERVER}:/tmp/

echo "Распаковка на сервере..."
ssh ${USER}@${SERVER} << EOF
mkdir -p ${REMOTE_DIR}
cd ${REMOTE_DIR}
tar -xzf /tmp/admin.tar.gz
rm /tmp/admin.tar.gz
rm -rf /var/www/168-222-193-86.regru.cloud/data/www/*.html
rm -rf /var/www/168-222-193-86.regru.cloud/data/www/*.php
echo "Файлы загружены!"
echo "Выполните на сервере:"
echo "  cd ${REMOTE_DIR}"
echo "  npm install"
echo "  npm run build"
echo "  nano .env.local  # Настройте переменные окружения"
echo "  pm2 start npm --name deti-admin -- start"
EOF

rm admin.tar.gz
echo "Готово! Подключитесь к серверу для завершения настройки."
