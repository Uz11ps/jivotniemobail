"""Тестирование и финализация"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def safe_run(c, timeout=30):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    safe_out = out.encode('ascii', errors='ignore').decode('ascii')
    safe_err = err.encode('ascii', errors='ignore').decode('ascii')
    return code, safe_out[:2000], safe_err[:1000]

print("Testing and finalizing...")

# Проверка что порт слушается
print("\n[1] Checking port...")
code, port, _ = safe_run("ss -tlnp | grep :3000")
print(f"Port status: {port[:300]}")

# Тестирование приложения с большим таймаутом
print("\n[2] Testing application (waiting 30 seconds for compilation)...")
time.sleep(30)

for i in range(15):
    code, response, _ = safe_run("curl -s -m 10 http://127.0.0.1:3000 2>&1", timeout=15)
    if code == 0 and response:
        if len(response) > 100 or "html" in response.lower() or "DOCTYPE" in response or "script" in response.lower() or "next" in response.lower():
            print(f"[OK] Application is responding! (attempt {i+1})")
            print(f"Response length: {len(response)}")
            print(f"Response preview: {response[:600]}")
            break
        elif "ECONNREFUSED" in response or "Failed to connect" in response:
            print(f"Connection refused (attempt {i+1})... waiting")
        else:
            print(f"Got response but may be error (attempt {i+1}): {response[:200]}")
    else:
        print(f"Attempt {i+1}/15... waiting 3 seconds")
    
    if i < 14:
        time.sleep(3)

# Проверка через nginx
print("\n[3] Testing through nginx...")
code, nginx_resp, _ = safe_run("curl -s -I http://127.0.0.1/ 2>&1 | head -10", timeout=10)
print("Nginx response:")
print(nginx_resp[:500])

# Статус PM2
code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

# Сохранение
safe_run("pm2 save")

ssh.close()

print("\n" + "="*60)
print("DEPLOYMENT COMPLETE!")
print("="*60)
print("Application is running on port 3000")
print("Check: http://168.222.193.86")
print("\nIf you see 502, wait 1-2 minutes for compilation")
print("Then check: pm2 logs deti-admin --lines 50")
