"""Ожидание и проверка"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def safe_run(c, timeout=60):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    safe_out = out.encode('ascii', errors='ignore').decode('ascii')
    safe_err = err.encode('ascii', errors='ignore').decode('ascii')
    return code, safe_out[:8000], safe_err[:6000]

print("Waiting and checking...")

# Проверка что порт слушается
code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
if "NOT_FOUND" in port_check:
    print("Port not listening, restarting...")
    safe_run("pm2 restart deti-admin")
    time.sleep(30)
else:
    print(f"Port is listening: {port_check[:300]}")

# Ждем и проверяем несколько раз
print("\n[1] Waiting and testing (5 minutes)...")
for i in range(30):
    code, response, _ = safe_run("curl -s -m 3 http://127.0.0.1:3000 2>&1", timeout=5)
    if response and len(response) > 50 and "502" not in response and "Bad Gateway" not in response:
        print(f"[OK] Application is responding! (attempt {i+1})")
        print(f"Response length: {len(response)}")
        print(response[:1000])
        
        # Тест через Nginx
        code, nginx_response, _ = safe_run("curl -s http://127.0.0.1/ 2>&1 | head -30", timeout=10)
        if nginx_response and len(nginx_response) > 50 and "502" not in nginx_response:
            print("\n[OK] Application is accessible through Nginx!")
            print(nginx_response[:1000])
        break
    else:
        if i % 5 == 0:
            print(f"Attempt {i+1}/30... waiting 10 seconds")
            # Проверка логов
            code, logs, _ = safe_run("pm2 logs deti-admin --lines 10 --nostream 2>&1", timeout=30)
            if logs and len(logs) > 100:
                print(f"Recent logs: {logs[:500]}")
        time.sleep(10)

# Финальная проверка
print("\n[2] Final check...")
code, final_port, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print(f"Port: {final_port[:300]}")

code, final_response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=10)
if final_response and len(final_response) > 50:
    print(f"[OK] Direct response: {final_response[:500]}")
else:
    print(f"No direct response: {final_response[:200]}")

code, nginx_final, _ = safe_run("curl -s -I http://127.0.0.1/ 2>&1 | head -5", timeout=10)
print(f"\nNginx response: {nginx_final[:300]}")

code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

ssh.close()

print("\nDone!")
