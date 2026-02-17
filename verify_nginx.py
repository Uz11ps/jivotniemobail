"""Проверка Nginx"""
import paramiko

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
    return code, safe_out[:4000], safe_err[:2000]

print("Verifying Nginx access...")

# Проверка порта
code, port, _ = safe_run("ss -tlnp | grep :3000")
print(f"Port 3000: {port[:300]}")

# Тест напрямую
code, direct, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1")
print(f"\nDirect response: {direct[:300]}")

# Тест через Nginx
code, nginx, _ = safe_run("curl -s http://127.0.0.1/ 2>&1")
print(f"\nNginx response: {nginx[:500]}")

if nginx and len(nginx) > 50 and "502" not in nginx:
    print("\n" + "="*60)
    print("SUCCESS! Application is accessible!")
    print("="*60)
    print("URL: http://168.222.193.86")
else:
    print("\nStill 502, checking Nginx config...")
    code, nginx_config, _ = safe_run("grep -A 10 'proxy_pass' /etc/nginx/sites-enabled/deti-admin.conf 2>&1 | head -15")
    print(f"Nginx config: {nginx_config[:800]}")

ssh.close()

print("\nDone!")
