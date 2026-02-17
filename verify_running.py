"""Проверка работы приложения"""
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
    return code, safe_out[:4000], safe_err[:2000]

print("Verifying application status...")

# Проверка процессов
print("\n[1] Checking processes...")
code, procs, _ = safe_run("ps aux | grep -E 'next|node' | grep -v grep")
print("Processes:")
print(procs[:1000])

# Проверка портов
print("\n[2] Checking ports...")
code, ports, _ = safe_run("ss -tlnp | grep :3000 || lsof -i :3000 || echo 'NOT_FOUND'")
print(f"Port 3000: {ports[:500]}")

# Полные логи
print("\n[3] Full output logs...")
code, out_logs, _ = safe_run("pm2 logs deti-admin --out --lines 50 --nostream 2>&1", timeout=90)
print("Output logs:")
print(out_logs[:3000])

# Тест запроса
print("\n[4] Testing request...")
code, response, _ = safe_run("curl -v http://127.0.0.1:3000 2>&1 | head -20", timeout=15)
print("Curl response:")
print(response[:800])

# Статус PM2
code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

ssh.close()

print("\nDone!")
