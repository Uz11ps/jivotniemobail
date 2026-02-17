"""Проверка полных логов"""
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
    return code, safe_out[:4000], safe_err[:2000]

print("Checking full logs...")

# Полные логи
print("\n[1] Full output logs (last 100 lines)...")
code, out_logs, _ = safe_run("pm2 logs deti-admin --out --lines 100 --nostream 2>&1", timeout=90)
print("Output logs:")
print(out_logs[:4000])

print("\n[2] Full error logs (last 100 lines)...")
code, err_logs, _ = safe_run("pm2 logs deti-admin --err --lines 100 --nostream 2>&1", timeout=90)
print("Error logs:")
print(err_logs[:4000])

# Проверка что происходит при запросе
print("\n[3] Testing direct request...")
code, curl_out, _ = safe_run("curl -v http://127.0.0.1:3000 2>&1 | head -30", timeout=20)
print("Curl output:")
print(curl_out[:1000])

# Проверка процессов
print("\n[4] Checking processes...")
code, procs, _ = safe_run("ps aux | grep -E 'node|next|npm' | grep -v grep | head -10")
print("Processes:")
print(procs[:800])

# Проверка порта
print("\n[5] Checking port 3000...")
code, port_info, _ = safe_run("lsof -i :3000 2>/dev/null || ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print("Port info:")
print(port_info[:500])

ssh.close()

print("\nDone!")
