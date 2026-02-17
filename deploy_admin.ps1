$ErrorActionPreference = "Stop"

# --- Настройки ---
$HostName = "168.222.193.86"
$UserName = "root"

# Куда деплоим Next.js админку на сервере.
# ecosystem.config.js сейчас ожидает /root/deti-admin
$RemoteDir = "/root/deti-admin"

# --- Пути локально ---
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$AdminDir = Join-Path $RepoRoot "admin"
$TarPath = Join-Path $RepoRoot "deti-admin.tgz"

if (!(Test-Path $AdminDir)) {
  throw "Не найдена папка admin: $AdminDir"
}

Write-Host "==> Packaging admin/ to deti-admin.tgz"

if (Test-Path $TarPath) { Remove-Item $TarPath -Force }

# Упаковываем СОДЕРЖИМОЕ папки admin (не весь репозиторий)
# Исключаем node_modules и сборочные артефакты.
tar -czf "$TarPath" `
  --exclude="node_modules" `
  --exclude=".next" `
  --exclude=".turbo" `
  --exclude=".env" `
  --exclude=".env.local" `
  --exclude=".env.production" `
  -C "$AdminDir" .

Write-Host "==> Uploading archive to server (will ask password)"
scp "$TarPath" "$UserName@$HostName:/tmp/deti-admin.tgz"

Write-Host "==> Deploying on server (will ask password again if needed)"

$RemoteCmd = @"
set -e

ARCHIVE="/tmp/deti-admin.tgz"
REMOTE_DIR="$RemoteDir"
TS=\$(date +%F_%H%M%S)
BACKUP_DIR="\${REMOTE_DIR}_backup_\${TS}"
STAGE_DIR="/tmp/deti-admin_stage_\${TS}"

echo "==> Stage dir: \$STAGE_DIR"
rm -rf "\$STAGE_DIR"
mkdir -p "\$STAGE_DIR"
tar -xzf "\$ARCHIVE" -C "\$STAGE_DIR"

echo "==> Backup old release (if any)"
if [ -d "\$REMOTE_DIR" ]; then
  mv "\$REMOTE_DIR" "\$BACKUP_DIR"
  echo "Backed up to: \$BACKUP_DIR"
fi

echo "==> Move new release"
mv "\$STAGE_DIR" "\$REMOTE_DIR"

echo "==> Restore env files (if existed)"
if [ -d "\$BACKUP_DIR" ]; then
  if [ -f "\$BACKUP_DIR/.env.production" ]; then cp "\$BACKUP_DIR/.env.production" "\$REMOTE_DIR/.env.production"; fi
  if [ -f "\$BACKUP_DIR/.env.local" ]; then cp "\$BACKUP_DIR/.env.local" "\$REMOTE_DIR/.env.local"; fi
fi

cd "\$REMOTE_DIR"

echo "==> Install deps"
if [ -f package-lock.json ]; then
  npm ci
else
  npm install
fi

echo "==> Build"
npm run build

echo "==> Restart via pm2"
if command -v pm2 >/dev/null 2>&1; then
  if [ -f ecosystem.config.js ]; then
    pm2 startOrRestart ecosystem.config.js
  else
    # fallback: start next directly
    pm2 start npm --name deti-admin -- start
  fi
  pm2 save || true
  pm2 status deti-admin || pm2 status || true
else
  echo "pm2 not found. Please install pm2 and start the app."
  exit 1
fi

echo "==> Done"
"@

ssh "$UserName@$HostName" $RemoteCmd

Write-Host ""
Write-Host "✅ Deploy finished. Check your site / admin panel."
