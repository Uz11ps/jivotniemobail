"""Простое исправление 502"""
import paramiko
import time
import sys

# Настройка вывода для Windows
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
print("Connecting...")
ssh.connect(SERVER, 22, USER, PASSWORD)

def cmd(c, timeout=60):
    try:
        _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
        code = stdout.channel.recv_exit_status()
        out = stdout.read().decode(errors="replace", encoding="utf-8")
        return code, out[:1000] if out else ""
    except Exception as e:
        return -1, str(e)

print("\n[1] Stopping PM2 processes...")
cmd("pm2 delete all 2>/dev/null || true")
time.sleep(3)

print("[2] Checking port 3000...")
code, out = cmd("lsof -i :3000 2>/dev/null || ss -tlnp | grep :3000 || echo 'free'")
if "3000" in out and "free" not in out:
    print("  Port 3000 is busy, killing processes...")
    cmd("pkill -f 'node.*3000' || pkill -f 'next' || true")
    time.sleep(2)

print("[3] Cleaning...")
cmd(f"cd {REMOTE_DIR} && rm -rf .next node_modules/.cache")

print("[4] Starting application in dev mode...")
code, out = cmd(f"cd {REMOTE_DIR} && pm2 start npm --name deti-admin -- run dev")
print(f"  Exit code: {code}")

print("[5] Waiting for startup (20 seconds)...")
time.sleep(20)

print("[6] Checking application...")
for i in range(3):
    code, out = cmd("curl -s http://127.0.0.1:3000 2>&1 | head -5")
    if code == 0 and (len(out) > 50 or "html" in out.lower() or "next" in out.lower()):
        print(f"  [OK] Application is working! (attempt {i+1})")
        break
    else:
        print(f"  Attempt {i+1}/3... waiting 5 seconds")
        time.sleep(5)

print("[7] Saving PM2...")
cmd("pm2 save")

print("\n[8] Final check...")
code, status = cmd("pm2 list")
print("PM2 status:")
print(status[:600])

code, nginx = cmd("curl -s -I http://127.0.0.1/ 2>&1 | head -3")
print("\nNginx check:")
print(nginx[:200])

ssh.close()

print("\n" + "="*60)
print("DONE!")
print("="*60)
print("Check: http://168.222.193.86")
print("If still 502, wait 1-2 minutes and check logs:")
print("  ssh root@168.222.193.86 'pm2 logs deti-admin'")
