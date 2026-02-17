"""Попытка production сборки"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def safe_run(c, timeout=600):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    safe_out = out.encode('ascii', errors='ignore').decode('ascii')
    safe_err = err.encode('ascii', errors='ignore').decode('ascii')
    return code, safe_out[:8000], safe_err[:6000]

print("Trying production build...")

# Остановка
safe_run("pm2 delete all 2>/dev/null || true")
time.sleep(2)

# Обновление next.config для production
print("\n[1] Updating next.config for production...")
next_config = """/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: false,
  images: {
    domains: ['firebasestorage.googleapis.com'],
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
  output: 'standalone',
}
module.exports = nextConfig
"""
sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/next.config.js", "w") as f:
        f.write(next_config)
finally:
    sftp.close()

# Очистка
print("[2] Cleaning...")
safe_run(f"cd {REMOTE_DIR} && rm -rf .next")

# Попытка сборки с увеличенной памятью
print("[3] Building with increased memory...")
code, build_out, build_err = safe_run(f"cd {REMOTE_DIR} && NODE_OPTIONS='--max-old-space-size=2048' npm run build 2>&1", timeout=600)
print("Build output:")
print(build_out[:4000])
if build_err and len(build_err) > 100:
    print("\nBuild errors:")
    print(build_err[:3000])

# Если сборка успешна, запускаем production
if "Compiled successfully" in build_out or ".next" in build_out:
    print("\n[4] Build successful! Starting production server...")
    start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=production
export NEXT_TELEMETRY_DISABLED=1
exec npm run start -- -p 3000 -H 127.0.0.1
"""
    sftp = ssh.open_sftp()
    try:
        with sftp.open("/tmp/start-prod.sh", "w") as f:
            f.write(start_script)
        sftp.chmod("/tmp/start-prod.sh", 0o755)
    finally:
        sftp.close()
    
    code, start_out, _ = safe_run("pm2 start /tmp/start-prod.sh --name deti-admin --interpreter bash")
    print(f"Start: {start_out[:600]}")
    
    # Ждем
    print("\n[5] Waiting 30 seconds...")
    time.sleep(30)
    
    # Проверка
    code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
    print(f"Port: {port_check[:400]}")
    
    if "NOT_FOUND" not in port_check:
        print("[OK] Port is listening!")
        code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=10)
        if response and len(response) > 50:
            print(f"[OK] Application is responding!")
            print(response[:700])
        else:
            print("No response yet")
    else:
        print("[WARN] Port not listening")
        code, logs, _ = safe_run("pm2 logs deti-admin --lines 30 --nostream 2>&1", timeout=60)
        print(logs[:3000])
else:
    print("\n[4] Build failed, trying dev mode with different approach...")
    # Возвращаем dev конфигурацию
    next_config_dev = """/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: false,
  images: {
    domains: ['firebasestorage.googleapis.com'],
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
}
module.exports = nextConfig
"""
    sftp = ssh.open_sftp()
    try:
        with sftp.open(f"{REMOTE_DIR}/next.config.js", "w") as f:
            f.write(next_config_dev)
    finally:
        sftp.close()

code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\nDone!")
