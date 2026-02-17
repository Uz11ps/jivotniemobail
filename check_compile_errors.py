"""Проверка ошибок компиляции"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def safe_run(c, timeout=300):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    safe_out = out.encode('ascii', errors='ignore').decode('ascii')
    safe_err = err.encode('ascii', errors='ignore').decode('ascii')
    return code, safe_out[:8000], safe_err[:6000]

print("Checking compilation errors...")

# Запуск с полным выводом ошибок
print("\n[1] Running with full error output...")
run_cmd = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
timeout 60 npm run dev -- -p 3000 -H 127.0.0.1 2>&1 | tee /tmp/nextjs-full.log
"""
code, full_output, _ = safe_run(run_cmd, timeout=70)
print("Full output:")
print(full_output[:6000])

# Проверка лога
code, log_content, _ = safe_run("cat /tmp/nextjs-full.log 2>&1 | tail -200")
print("\n[2] Log file content:")
print(log_content[:6000])

# Проверка на наличие ошибок компиляции
if "error" in full_output.lower() or "Error" in full_output or "Failed" in full_output:
    print("\n[3] Errors found! Checking specific files...")
    
    # Проверка TypeScript ошибок
    code, ts_errors, _ = safe_run(f"cd {REMOTE_DIR} && npx tsc --noEmit 2>&1 | head -50", timeout=60)
    if ts_errors and len(ts_errors) > 100:
        print("TypeScript errors:")
        print(ts_errors[:3000])

ssh.close()

print("\nDone!")
