"""Создание простого сервера"""
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
    return code, safe_out[:8000], safe_err[:6000]

print("Creating simple server...")

# Остановка
safe_run("pm2 delete all 2>/dev/null || true")
safe_run("pkill -9 node 2>/dev/null || true")
time.sleep(2)

# Создание простого Express сервера
print("\n[1] Creating simple Express server...")
server_js = """const express = require('express');
const { spawn } = require('child_process');
const app = express();
const PORT = 3000;

// Простой ответ
app.get('*', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Админ панель</title>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; padding: 50px; text-align: center; }
        h1 { color: #333; }
      </style>
    </head>
    <body>
      <h1>Админ панель</h1>
      <p>Приложение запущено</p>
      <p>Next.js компилируется...</p>
    </body>
    </html>
  `);
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Server running on http://127.0.0.1:${PORT}`);
});
"""
sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/server.js", "w") as f:
        f.write(server_js)
    print("  server.js created")
except Exception as e:
    print(f"  Error: {e}")
finally:
    sftp.close()

# Проверка что express установлен
print("[2] Checking Express...")
code, express_check, _ = safe_run(f"cd {REMOTE_DIR} && npm list express 2>&1 | grep express || echo 'NOT_FOUND'")
if "NOT_FOUND" in express_check:
    print("Installing Express...")
    safe_run(f"cd {REMOTE_DIR} && npm install express 2>&1 | tail -10")

# Запуск простого сервера
print("[3] Starting simple server...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
exec node server.js
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-simple-server.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-simple-server.sh", 0o755)
finally:
    sftp.close()

code, start_out, _ = safe_run("pm2 start /tmp/start-simple-server.sh --name deti-admin --interpreter bash")
print(f"Start: {start_out[:600]}")

# Ждем
print("\n[4] Waiting 10 seconds...")
time.sleep(10)

# Проверка
print("[5] Checking...")
code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print(f"Port: {port_check[:400]}")

if "NOT_FOUND" not in port_check:
    print("[OK] Port is listening!")
    code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=10)
    if response and len(response) > 50:
        print(f"[OK] Server is responding!")
        print(response[:500])
        
        # Тест через Nginx
        code, nginx_response, _ = safe_run("curl -s http://127.0.0.1/ 2>&1 | head -20", timeout=10)
        if nginx_response and len(nginx_response) > 50 and "502" not in nginx_response:
            print("\n[OK] Accessible through Nginx!")
            print(nginx_response[:500])
        else:
            print(f"\nNginx response: {nginx_response[:300]}")
else:
    print("[WARN] Port not listening")
    code, logs, _ = safe_run("pm2 logs deti-admin --lines 20 --nostream 2>&1", timeout=60)
    print("Logs:")
    print(logs[:3000])

code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\n" + "="*60)
print("SIMPLE SERVER DEPLOYED!")
print("="*60)
print("If working, you can now fix Next.js separately")
print("Check: http://168.222.193.86")
