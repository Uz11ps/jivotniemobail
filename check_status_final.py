"""Финальная проверка статуса"""
import paramiko

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
    return code, safe_out[:5000], safe_err[:3000]

print("Final status check...")

# Статус PM2
code, status, _ = safe_run("pm2 list")
print("PM2 Status:")
print(status[:800])

# Полные логи
print("\n[1] Full output logs (last 100 lines)...")
code, out_logs, _ = safe_run("pm2 logs deti-admin --out --lines 100 --nostream 2>&1", timeout=120)
print("Output logs:")
print(out_logs[:4000])

print("\n[2] Full error logs (last 100 lines)...")
code, err_logs, _ = safe_run("pm2 logs deti-admin --err --lines 100 --nostream 2>&1", timeout=120)
print("Error logs:")
print(err_logs[:4000])

# Проверка портов
code, ports, _ = safe_run("ss -tlnp | grep :3000 || lsof -i :3000 || echo 'NOT_FOUND'")
print(f"\nPort 3000: {ports[:500]}")

# Проверка процессов
code, procs, _ = safe_run("ps aux | grep -E 'next|node.*3000' | grep -v grep")
print("\nProcesses:")
print(procs[:1000])

# Тест запроса
code, response, _ = safe_run("curl -v http://127.0.0.1:3000 2>&1 | head -25", timeout=15)
print("\nCurl test:")
print(response[:1000])

ssh.close()

print("\nDone!")
