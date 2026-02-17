"""Проверка Nginx и тестирование"""
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
    return code, safe_out[:6000], safe_err[:4000]

print("Checking Nginx and testing application...")

# Проверка порта
print("\n[1] Checking port 3000...")
code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print(f"Port: {port_check[:400]}")

# Тест приложения напрямую
print("\n[2] Testing application directly...")
for i in range(10):
    code, response, _ = safe_run("curl -s -m 5 http://127.0.0.1:3000 2>&1", timeout=10)
    if response and len(response) > 50:
        print(f"[OK] Application is responding! (attempt {i+1})")
        print(f"Response length: {len(response)}")
        print(response[:800])
        break
    else:
        if i < 9:
            print(f"Attempt {i+1}/10... waiting 3 seconds")
            time.sleep(3)
        else:
            print("No response after 10 attempts")

# Проверка Nginx конфигурации
print("\n[3] Checking Nginx configuration...")
code, nginx_config, _ = safe_run("find /etc/nginx -name '*168-222-193-86*' -o -name '*deti*' 2>/dev/null | head -5")
print(f"Nginx config files: {nginx_config[:500]}")

# Проверка конфигурации для домена
code, nginx_sites, _ = safe_run("ls -la /etc/nginx/sites-enabled/ 2>/dev/null | head -10")
print(f"\nNginx sites: {nginx_sites[:500]}")

# Проверка конфигурации через ISPmanager
code, isp_config, _ = safe_run("grep -r '168-222-193-86' /etc/nginx/ 2>/dev/null | head -10")
if isp_config:
    print(f"\nISPmanager config: {isp_config[:1000]}")

# Тест через Nginx
print("\n[4] Testing through Nginx...")
code, nginx_response, _ = safe_run("curl -s -I http://127.0.0.1/ 2>&1 | head -10", timeout=10)
print("Nginx response:")
print(nginx_response[:500])

# Если 502, проверяем upstream
if "502" in nginx_response or "Bad Gateway" in nginx_response:
    print("\n[5] 502 error detected, checking upstream configuration...")
    code, upstream_check, _ = safe_run("grep -A 5 'proxy_pass\\|upstream' /etc/nginx/sites-enabled/* 2>/dev/null | head -20")
    if upstream_check:
        print("Upstream config:")
        print(upstream_check[:1000])
    
    # Попытка исправить Nginx конфигурацию
    print("\n[6] Attempting to fix Nginx configuration...")
    # Ищем конфигурационный файл
    code, config_file, _ = safe_run("grep -l '168-222-193-86' /etc/nginx/sites-enabled/* 2>/dev/null | head -1")
    if config_file and len(config_file.strip()) > 0:
        config_file = config_file.strip()
        print(f"Found config file: {config_file}")
        
        # Читаем текущую конфигурацию
        code, current_config, _ = safe_run(f"cat {config_file} 2>&1")
        print(f"\nCurrent config:\n{current_config[:1500]}")
        
        # Обновляем upstream на правильный адрес
        if "proxy_pass" in current_config:
            # Заменяем upstream на 127.0.0.1:3000
            updated_config = current_config.replace("proxy_pass http://", "proxy_pass http://127.0.0.1:3000/")
            if updated_config != current_config:
                sftp = ssh.open_sftp()
                try:
                    with sftp.open(config_file, "w") as f:
                        f.write(updated_config)
                    print("Config updated")
                    safe_run("nginx -t")
                    safe_run("systemctl reload nginx || service nginx reload")
                    print("Nginx reloaded")
                except Exception as e:
                    print(f"Error updating config: {e}")
                finally:
                    sftp.close()

# Финальная проверка
print("\n[7] Final check...")
time.sleep(5)
code, final_response, _ = safe_run("curl -s http://127.0.0.1/ 2>&1 | head -20", timeout=10)
if final_response and len(final_response) > 50 and "502" not in final_response:
    print("[OK] Application is accessible through Nginx!")
    print(final_response[:800])
else:
    print("Still having issues")
    print(final_response[:500])

ssh.close()

print("\nDone!")
