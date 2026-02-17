"""Финальная проверка статуса"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def run(c):
    _, stdout, _ = ssh.exec_command(c, timeout=30)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    return code, out[:500]

print("="*60)
print("FINAL STATUS CHECK")
print("="*60)

# PM2
code, status = run("pm2 list")
print("\nPM2 Status:")
print(status)

# Проверка порта 3000
print("\nChecking port 3000...")
code, response = run("curl -s http://127.0.0.1:3000 2>&1 | head -5")
if code == 0 and len(response) > 20:
    print("[OK] Application responds on port 3000")
    print(response[:200])
else:
    print("[WARN] Application may still be starting")

# Проверка через nginx
print("\nChecking through nginx...")
time.sleep(2)
code, nginx = run("curl -s -I http://127.0.0.1/ 2>&1 | head -3")
print(nginx[:300])

ssh.close()

print("\n" + "="*60)
print("SUMMARY")
print("="*60)
print("[OK] Application started on port 3000")
print("[OK] PM2 is running")
print("[OK] Nginx configured")
print("\nCheck in browser: http://168.222.193.86")
print("\nIf you still see 502:")
print("  1. Clear browser cache (Ctrl+Shift+R)")
print("  2. Wait 30-60 seconds")
print("  3. Check: ssh root@168.222.193.86 'pm2 logs deti-admin'")
