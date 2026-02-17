"""Быстрый запуск Next.js"""
import paramiko
import time

SERVER = "168.222.193.86"
USER = "root"
PASSWORD = "tioSvryiHaPKXWMU"
REMOTE_DIR = "/var/www/168-222-193-86.regru.cloud/data/www/deti-admin"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SERVER, 22, USER, PASSWORD)

def safe_run(c, timeout=120):
    _, stdout, stderr = ssh.exec_command(c, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="replace", encoding="utf-8")
    err = stderr.read().decode(errors="replace", encoding="utf-8")
    safe_out = out.encode('ascii', errors='ignore').decode('ascii')
    safe_err = err.encode('ascii', errors='ignore').decode('ascii')
    return code, safe_out[:8000], safe_err[:6000]

print("Quick Next.js start...")

# Остановка
safe_run("pm2 delete deti-admin 2>/dev/null || true")
safe_run("pkill -9 node 2>/dev/null || true")
time.sleep(2)

# Проверка что файлы на месте
code, page_exists, _ = safe_run(f"test -f {REMOTE_DIR}/src/app/page.tsx && echo 'EXISTS' || echo 'MISSING'")
code, layout_exists, _ = safe_run(f"test -f {REMOTE_DIR}/src/app/layout.tsx && echo 'EXISTS' || echo 'MISSING'")
print(f"page.tsx: {page_exists[:50]}")
print(f"layout.tsx: {layout_exists[:50]}")

# Если файлы есть, просто запускаем
if "EXISTS" in page_exists and "EXISTS" in layout_exists:
    print("\n[1] Files exist, starting Next.js...")
    start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
export NODE_OPTIONS='--max-old-space-size=1024'
exec npm run dev -- -p 3000 -H 127.0.0.1
"""
    sftp = ssh.open_sftp()
    try:
        with sftp.open("/tmp/start-next.sh", "w") as f:
            f.write(start_script)
        sftp.chmod("/tmp/start-next.sh", 0o755)
    finally:
        sftp.close()
    
    code, start_out, _ = safe_run("pm2 start /tmp/start-next.sh --name deti-admin --interpreter bash")
    print(f"Started: {start_out[:500]}")
    
    # Ждем 2 минуты
    print("\n[2] Waiting 2 minutes for compilation...")
    time.sleep(120)
    
    # Проверка
    code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
    print(f"Port: {port_check[:300]}")
    
    if "NOT_FOUND" not in port_check:
        code, response, _ = safe_run("curl -s http://127.0.0.1:3000 2>&1", timeout=10)
        if response and len(response) > 50:
            print(f"[OK] Next.js responding! Length: {len(response)}")
            print(response[:500])
            
            code, nginx_resp, _ = safe_run("curl -s http://127.0.0.1/ 2>&1", timeout=10)
            if nginx_resp and len(nginx_resp) > 50:
                print("\n[OK] Accessible through Nginx!")
                print(nginx_resp[:500])
        else:
            print("No response yet, may still be compiling")
    else:
        print("Port not listening")
        code, logs, _ = safe_run("pm2 logs deti-admin --lines 20 --nostream 2>&1", timeout=60)
        print("Logs:")
        print(logs[:2000])
else:
    print("\n[1] Files missing, restoring...")
    # Восстанавливаем файлы
    layout_tsx = """import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Админ панель',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html><body>{children}</body></html>
}
"""
    page_tsx = """'use client';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function Home() {
  const router = useRouter();
  useEffect(() => { router.push('/login'); }, [router]);
  return <div>Перенаправление...</div>;
}
"""
    globals_css = """body { margin: 0; }
"""
    
    sftp = ssh.open_sftp()
    try:
        with sftp.open(f"{REMOTE_DIR}/src/app/layout.tsx", "w") as f:
            f.write(layout_tsx)
        with sftp.open(f"{REMOTE_DIR}/src/app/page.tsx", "w") as f:
            f.write(page_tsx)
        with sftp.open(f"{REMOTE_DIR}/src/app/globals.css", "w") as f:
            f.write(globals_css)
    finally:
        sftp.close()
    
    print("Files restored, restart script to start Next.js")

code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\nDone! Check http://168.222.193.86")
