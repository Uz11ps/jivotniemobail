"""Проверка логов для диагностики проблемы"""
import paramiko
import sys

if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def cmd(c, timeout=60):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    return code, out, err

print("="*60)
print("DIAGNOSTICS")
print("="*60)

print("\n[1] PM2 Logs (last 50 lines):")
code, out, err = cmd("pm2 logs deti-admin --lines 50 --nostream 2>&1", timeout=60)
print(out[:2000] if out else err[:1000])

print("\n[2] Checking .env.local:")
code, env, _ = cmd(f"head -5 {REMOTE_DIR}/.env.local 2>/dev/null || echo 'NOT_FOUND'")
print(env[:500])

print("\n[3] Checking package.json:")
code, pkg, _ = cmd(f"head -20 {REMOTE_DIR}/package.json 2>/dev/null")
print(pkg[:500])

print("\n[4] Checking if node_modules exists:")
code, nm, _ = cmd(f"test -d {REMOTE_DIR}/node_modules && echo 'EXISTS' || echo 'MISSING'")
print(nm)

print("\n[5] Trying to start manually to see errors:")
code, manual, _ = cmd(f"cd {REMOTE_DIR} && timeout 10 npm run dev 2>&1 || true")
print(manual[:1500])

ssh.close()

print("\n" + "="*60)
print("Check the output above for errors")
print("="*60)
