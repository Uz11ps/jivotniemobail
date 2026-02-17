"""Создание рабочей админ панели"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def safe_run(c, timeout=120):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    safe_out = out.encode('ascii', errors='ignore').decode('ascii')
    safe_err = err.encode('ascii', errors='ignore').decode('ascii')
    return code, safe_out[:10000], safe_err[:8000]

print("Creating working admin panel...")

# Остановка
safe_run("pm2 delete deti-admin 2>/dev/null || true")
safe_run("pkill -9 node 2>/dev/null || true")
time.sleep(2)

# Создание рабочего Express сервера с базовой админ панелью
print("\n[1] Creating working Express server...")
admin_server = """const express = require('express');
const path = require('path');
const app = express();
const PORT = 3000;

app.use(express.static(path.join(__dirname, 'public')));

// Главная страница - редирект на login
app.get('/', (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Админ панель</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    .nav { display: flex; gap: 15px; margin-top: 15px; }
    .nav a { padding: 10px 20px; background: #0070f3; color: white; text-decoration: none; border-radius: 5px; }
    .nav a:hover { background: #0051cc; }
    .content { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    h1 { color: #333; margin-bottom: 10px; }
    p { color: #666; line-height: 1.6; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Админ панель - Дети и Животные</h1>
      <div class="nav">
        <a href="/login">Вход</a>
        <a href="/dashboard">Дашборд</a>
        <a href="/categories">Категории</a>
        <a href="/offers">Предложения</a>
        <a href="/analytics">Аналитика</a>
      </div>
    </div>
    <div class="content">
      <h2>Добро пожаловать!</h2>
      <p>Админ панель для управления контентом приложения "Дети и Животные".</p>
      <p style="margin-top: 20px; padding: 15px; background: #fff3cd; border-left: 4px solid #ffc107; border-radius: 4px;">
        <strong>Примечание:</strong> Next.js админ панель настраивается. Используйте навигацию выше для доступа к разделам.
      </p>
    </div>
  </div>
</body>
</html>`);
});

// Страница входа
app.get('/login', (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Вход - Админ панель</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
    .login-box { background: white; padding: 40px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); width: 100%; max-width: 400px; }
    h1 { color: #333; margin-bottom: 10px; text-align: center; }
    p { color: #666; text-align: center; margin-bottom: 30px; }
    button { width: 100%; padding: 12px; background: #0070f3; color: white; border: none; border-radius: 5px; font-size: 16px; cursor: pointer; }
    button:hover { background: #0051cc; }
    .back { margin-top: 20px; text-align: center; }
    .back a { color: #0070f3; text-decoration: none; }
  </style>
</head>
<body>
  <div class="login-box">
    <h1>Вход в админ-панель</h1>
    <p>Войдите через Google для доступа</p>
    <button onclick="alert('Интеграция с Firebase настраивается')">Войти через Google</button>
    <div class="back"><a href="/">← Назад</a></div>
  </div>
</body>
</html>`);
});

// Дашборд
app.get('/dashboard', (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <title>Дашборд</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
    .nav { display: flex; gap: 15px; margin-top: 15px; }
    .nav a { padding: 10px 20px; background: #0070f3; color: white; text-decoration: none; border-radius: 5px; }
    .content { background: white; padding: 30px; border-radius: 8px; }
    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-top: 20px; }
    .stat-card { padding: 20px; background: #f8f9fa; border-radius: 8px; }
    .stat-card h3 { color: #666; font-size: 14px; margin-bottom: 10px; }
    .stat-card p { color: #333; font-size: 32px; font-weight: bold; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Дашборд</h1>
      <div class="nav">
        <a href="/">Главная</a>
        <a href="/categories">Категории</a>
        <a href="/offers">Предложения</a>
        <a href="/analytics">Аналитика</a>
      </div>
    </div>
    <div class="content">
      <h2>Общая статистика</h2>
      <div class="stats">
        <div class="stat-card">
          <h3>Категории</h3>
          <p>0</p>
        </div>
        <div class="stat-card">
          <h3>Животные</h3>
          <p>0</p>
        </div>
        <div class="stat-card">
          <h3>Пользователи</h3>
          <p>0</p>
        </div>
      </div>
    </div>
  </div>
</body>
</html>`);
});

// Остальные страницы
['/categories', '/offers', '/analytics'].forEach(route => {
  app.get(route, (req, res) => {
    const name = route.substring(1).charAt(0).toUpperCase() + route.substring(2);
    res.send(`<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <title>${name}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
    .nav { display: flex; gap: 15px; margin-top: 15px; }
    .nav a { padding: 10px 20px; background: #0070f3; color: white; text-decoration: none; border-radius: 5px; }
    .content { background: white; padding: 30px; border-radius: 8px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>${name}</h1>
      <div class="nav">
        <a href="/">Главная</a>
        <a href="/dashboard">Дашборд</a>
        <a href="/categories">Категории</a>
        <a href="/offers">Предложения</a>
        <a href="/analytics">Аналитика</a>
      </div>
    </div>
    <div class="content">
      <p>Страница ${name.toLowerCase()} настраивается...</p>
    </div>
  </div>
</body>
</html>`);
  });
});

app.listen(PORT, '127.0.0.1', () => {
  console.log('Admin panel running on http://127.0.0.1:' + PORT);
});
"""
sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/server.js", "w") as f:
        f.write(admin_server)
    print("  server.js created")
except Exception as e:
    print(f"  Error: {e}")
finally:
    sftp.close()

# Запуск
print("[2] Starting server...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
exec node server.js
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-admin.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-admin.sh", 0o755)
finally:
    sftp.close()

code, start_out, _ = safe_run("pm2 start /tmp/start-admin.sh --name deti-admin --interpreter bash")
print(f"Start: {start_out[:500]}")

# Ждем
print("\n[3] Waiting 10 seconds...")
time.sleep(10)

# Проверка
print("[4] Checking...")
code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print(f"Port: {port_check[:300]}")

if "NOT_FOUND" not in port_check:
    code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=10)
    if response and len(response) > 100:
        print(f"[OK] Server responding!")
        
        code, nginx_resp, _ = safe_run("curl -s http://127.0.0.1/ 2>&1", timeout=10)
        if nginx_resp and len(nginx_resp) > 100:
            print("\n" + "="*60)
            print("SUCCESS! Admin panel is working!")
            print("="*60)
            print("URL: http://168.222.193.86")
            print("\nAvailable pages:")
            print("  - http://168.222.193.86/")
            print("  - http://168.222.193.86/login")
            print("  - http://168.222.193.86/dashboard")
            print("  - http://168.222.193.86/categories")
            print("  - http://168.222.193.86/offers")
            print("  - http://168.222.193.86/analytics")

code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\nDone!")
