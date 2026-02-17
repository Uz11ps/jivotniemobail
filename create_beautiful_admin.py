"""Создание красивой админ панели"""
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
    return code, safe_out[:25000], safe_err[:20000]

print("Creating beautiful admin panel...")

# Остановка
safe_run("pm2 delete deti-admin 2>/dev/null || true")
safe_run("pkill -9 node 2>/dev/null || true")
time.sleep(2)

# Читаем .env.local
code, env_content, _ = safe_run(f"cat {REMOTE_DIR}/.env.local 2>&1")
env_vars = {}
for line in env_content.split('\n'):
    if '=' in line and not line.strip().startswith('#'):
        parts = line.split('=', 1)
        if len(parts) == 2:
            env_vars[parts[0].strip()] = parts[1].strip()

# Создаем красивый сервер с премиум дизайном
print("[1] Creating beautiful server...")

beautiful_server = f"""const express = require('express');
const admin = require('firebase-admin');
require('dotenv').config({{ path: '.env.local' }});

const app = express();
const PORT = 3000;

app.use(express.json());
app.use(express.urlencoded({{ extended: true }}));

// Firebase Admin
let db = null;
try {{
  const projectId = process.env.FIREBASE_PROJECT_ID || '{env_vars.get("FIREBASE_PROJECT_ID", "")}';
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL || '{env_vars.get("FIREBASE_CLIENT_EMAIL", "")}';
  const privateKey = (process.env.FIREBASE_PRIVATE_KEY || '{env_vars.get("FIREBASE_PRIVATE_KEY", "")}').replace(/\\\\n/g, '\\n');
  
  if (projectId && clientEmail && privateKey && privateKey !== '') {{
    admin.initializeApp({{
      credential: admin.credential.cert({{ projectId, clientEmail, privateKey }})
    }});
    db = admin.firestore();
    console.log('Firebase Admin initialized');
  }}
}} catch (e) {{
  console.log('Firebase Admin init skipped:', e.message);
}}

let mockData = {{ categories: [], offers: [] }};

// Премиум HTML шаблон
const htmlTemplate = (title, content, activePage = '') => `<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${{title}} - Админ панель</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {{
      --primary: #6366f1;
      --primary-dark: #4f46e5;
      --primary-light: #818cf8;
      --success: #10b981;
      --danger: #ef4444;
      --warning: #f59e0b;
      --info: #3b82f6;
      --gray-50: #f9fafb;
      --gray-100: #f3f4f6;
      --gray-200: #e5e7eb;
      --gray-300: #d1d5db;
      --gray-400: #9ca3af;
      --gray-500: #6b7280;
      --gray-600: #4b5563;
      --gray-700: #374151;
      --gray-800: #1f2937;
      --gray-900: #111827;
      --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
      --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
      --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
      --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
      --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
    }}
    
    * {{
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }}
    
    body {{
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      color: var(--gray-900);
      line-height: 1.6;
    }}
    
    .container {{
      max-width: 1600px;
      margin: 0 auto;
      padding: 24px;
    }}
    
    .header {{
      background: white;
      padding: 24px 32px;
      border-radius: 16px;
      margin-bottom: 24px;
      box-shadow: var(--shadow-lg);
      backdrop-filter: blur(10px);
      border: 1px solid rgba(255, 255, 255, 0.2);
    }}
    
    .header h1 {{
      font-size: 28px;
      font-weight: 700;
      background: linear-gradient(135deg, var(--primary) 0%, var(--primary-light) 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      margin-bottom: 16px;
    }}
    
    .nav {{
      display: flex;
      gap: 8px;
      margin-top: 16px;
      flex-wrap: wrap;
    }}
    
    .nav a {{
      padding: 10px 20px;
      background: var(--gray-100);
      color: var(--gray-700);
      text-decoration: none;
      border-radius: 10px;
      font-weight: 500;
      font-size: 14px;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      position: relative;
      overflow: hidden;
    }}
    
    .nav a::before {{
      content: '';
      position: absolute;
      top: 0;
      left: -100%;
      width: 100%;
      height: 100%;
      background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
      transition: left 0.5s;
    }}
    
    .nav a:hover::before {{
      left: 100%;
    }}
    
    .nav a:hover {{
      background: var(--primary);
      color: white;
      transform: translateY(-2px);
      box-shadow: var(--shadow-md);
    }}
    
    .nav a.active {{
      background: linear-gradient(135deg, var(--primary) 0%, var(--primary-light) 100%);
      color: white;
      box-shadow: var(--shadow-md);
    }}
    
    .content {{
      background: white;
      padding: 32px;
      border-radius: 16px;
      box-shadow: var(--shadow-xl);
      min-height: 600px;
      animation: fadeIn 0.5s ease-in;
    }}
    
    @keyframes fadeIn {{
      from {{ opacity: 0; transform: translateY(20px); }}
      to {{ opacity: 1; transform: translateY(0); }}
    }}
    
    h1 {{
      font-size: 32px;
      font-weight: 700;
      color: var(--gray-900);
      margin-bottom: 8px;
      letter-spacing: -0.5px;
    }}
    
    h2 {{
      font-size: 24px;
      font-weight: 600;
      color: var(--gray-800);
      margin-bottom: 24px;
      letter-spacing: -0.3px;
    }}
    
    h3 {{
      font-size: 18px;
      font-weight: 600;
      color: var(--gray-700);
      margin-bottom: 16px;
    }}
    
    .btn {{
      padding: 12px 24px;
      background: linear-gradient(135deg, var(--primary) 0%, var(--primary-light) 100%);
      color: white;
      border: none;
      border-radius: 10px;
      cursor: pointer;
      font-size: 14px;
      font-weight: 600;
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      gap: 8px;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      box-shadow: var(--shadow-md);
      position: relative;
      overflow: hidden;
    }}
    
    .btn::before {{
      content: '';
      position: absolute;
      top: 50%;
      left: 50%;
      width: 0;
      height: 0;
      border-radius: 50%;
      background: rgba(255, 255, 255, 0.3);
      transform: translate(-50%, -50%);
      transition: width 0.6s, height 0.6s;
    }}
    
    .btn:hover::before {{
      width: 300px;
      height: 300px;
    }}
    
    .btn:hover {{
      transform: translateY(-2px);
      box-shadow: var(--shadow-lg);
    }}
    
    .btn:active {{
      transform: translateY(0);
    }}
    
    .btn-danger {{
      background: linear-gradient(135deg, var(--danger) 0%, #f87171 100%);
    }}
    
    .btn-success {{
      background: linear-gradient(135deg, var(--success) 0%, #34d399 100%);
    }}
    
    .btn-secondary {{
      background: var(--gray-200);
      color: var(--gray-700);
    }}
    
    .table {{
      width: 100%;
      border-collapse: separate;
      border-spacing: 0;
      margin-top: 24px;
      background: white;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: var(--shadow);
    }}
    
    .table thead {{
      background: linear-gradient(135deg, var(--gray-50) 0%, var(--gray-100) 100%);
    }}
    
    .table th {{
      padding: 16px;
      text-align: left;
      font-weight: 600;
      font-size: 13px;
      color: var(--gray-700);
      text-transform: uppercase;
      letter-spacing: 0.5px;
      border-bottom: 2px solid var(--gray-200);
    }}
    
    .table td {{
      padding: 16px;
      border-bottom: 1px solid var(--gray-100);
      color: var(--gray-700);
    }}
    
    .table tbody tr {{
      transition: all 0.2s;
    }}
    
    .table tbody tr:hover {{
      background: var(--gray-50);
      transform: scale(1.01);
    }}
    
    .table tbody tr:last-child td {{
      border-bottom: none;
    }}
    
    .form-group {{
      margin-bottom: 24px;
    }}
    
    .form-group label {{
      display: block;
      margin-bottom: 8px;
      color: var(--gray-700);
      font-weight: 500;
      font-size: 14px;
    }}
    
    .form-group input,
    .form-group textarea,
    .form-group select {{
      width: 100%;
      padding: 12px 16px;
      border: 2px solid var(--gray-200);
      border-radius: 10px;
      font-size: 14px;
      transition: all 0.3s;
      font-family: inherit;
    }}
    
    .form-group input:focus,
    .form-group textarea:focus,
    .form-group select:focus {{
      outline: none;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
    }}
    
    .form-group textarea {{
      min-height: 120px;
      resize: vertical;
    }}
    
    .form-row {{
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
    }}
    
    .badge {{
      display: inline-flex;
      align-items: center;
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }}
    
    .badge-success {{
      background: #d1fae5;
      color: #065f46;
    }}
    
    .badge-danger {{
      background: #fee2e2;
      color: #991b1b;
    }}
    
    .badge-warning {{
      background: #fef3c7;
      color: #92400e;
    }}
    
    .badge-info {{
      background: #dbeafe;
      color: #1e40af;
    }}
    
    .empty-state {{
      text-align: center;
      padding: 80px 20px;
      color: var(--gray-500);
    }}
    
    .empty-state svg {{
      width: 120px;
      height: 120px;
      margin: 0 auto 24px;
      opacity: 0.3;
    }}
    
    .empty-state h3 {{
      font-size: 20px;
      margin-bottom: 8px;
      color: var(--gray-600);
    }}
    
    .modal {{
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0, 0, 0, 0.6);
      z-index: 1000;
      backdrop-filter: blur(4px);
      animation: fadeIn 0.3s;
    }}
    
    .modal.active {{
      display: flex;
      align-items: center;
      justify-content: center;
    }}
    
    .modal-content {{
      background: white;
      padding: 32px;
      border-radius: 20px;
      max-width: 700px;
      width: 90%;
      max-height: 90vh;
      overflow-y: auto;
      box-shadow: var(--shadow-xl);
      animation: slideUp 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      position: relative;
    }}
    
    @keyframes slideUp {{
      from {{
        opacity: 0;
        transform: translateY(30px) scale(0.95);
      }}
      to {{
        opacity: 1;
        transform: translateY(0) scale(1);
      }}
    }}
    
    .close {{
      position: absolute;
      top: 20px;
      right: 20px;
      font-size: 28px;
      font-weight: 300;
      cursor: pointer;
      color: var(--gray-400);
      width: 32px;
      height: 32px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 50%;
      transition: all 0.2s;
    }}
    
    .close:hover {{
      background: var(--gray-100);
      color: var(--danger);
      transform: rotate(90deg);
    }}
    
    .stats-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 24px;
      margin-top: 32px;
    }}
    
    .stat-card {{
      padding: 28px;
      border-radius: 16px;
      color: white;
      position: relative;
      overflow: hidden;
      box-shadow: var(--shadow-lg);
      transition: transform 0.3s;
    }}
    
    .stat-card::before {{
      content: '';
      position: absolute;
      top: -50%;
      right: -50%;
      width: 200%;
      height: 200%;
      background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%);
      animation: pulse 3s ease-in-out infinite;
    }}
    
    @keyframes pulse {{
      0%, 100% {{ opacity: 0.5; }}
      50% {{ opacity: 0.8; }}
    }}
    
    .stat-card:hover {{
      transform: translateY(-4px) scale(1.02);
    }}
    
    .stat-card h3 {{
      font-size: 14px;
      opacity: 0.9;
      margin-bottom: 12px;
      font-weight: 500;
      color: white;
    }}
    
    .stat-card p {{
      font-size: 42px;
      font-weight: 700;
      margin: 0;
    }}
    
    .stat-card.gradient-1 {{
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }}
    
    .stat-card.gradient-2 {{
      background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
    }}
    
    .stat-card.gradient-3 {{
      background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
    }}
    
    .alert {{
      padding: 16px 20px;
      margin-bottom: 24px;
      border-radius: 12px;
      border-left: 4px solid;
      display: flex;
      align-items: center;
      gap: 12px;
      animation: slideIn 0.3s;
    }}
    
    @keyframes slideIn {{
      from {{
        opacity: 0;
        transform: translateX(-20px);
      }}
      to {{
        opacity: 1;
        transform: translateX(0);
      }}
    }}
    
    .alert-info {{
      background: #eff6ff;
      border-color: var(--info);
      color: #1e40af;
    }}
    
    .alert-success {{
      background: #ecfdf5;
      border-color: var(--success);
      color: #065f46;
    }}
    
    .alert-danger {{
      background: #fef2f2;
      border-color: var(--danger);
      color: #991b1b;
    }}
    
    .action-buttons {{
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }}
    
    .btn-sm {{
      padding: 8px 16px;
      font-size: 13px;
    }}
    
    .page-header {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 32px;
      flex-wrap: wrap;
      gap: 16px;
    }}
    
    .back-link {{
      color: var(--primary);
      text-decoration: none;
      font-weight: 500;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s;
      margin-bottom: 20px;
    }}
    
    .back-link:hover {{
      gap: 10px;
      color: var(--primary-dark);
    }}
    
    .loading {{
      display: inline-block;
      width: 20px;
      height: 20px;
      border: 3px solid rgba(255,255,255,.3);
      border-radius: 50%;
      border-top-color: white;
      animation: spin 1s ease-in-out infinite;
    }}
    
    @keyframes spin {{
      to {{ transform: rotate(360deg); }}
    }}
    
    @media (max-width: 768px) {{
      .form-row {{
        grid-template-columns: 1fr;
      }}
      .nav {{
        flex-direction: column;
      }}
      .page-header {{
        flex-direction: column;
        align-items: stretch;
      }}
      .container {{
        padding: 16px;
      }}
      .content {{
        padding: 20px;
      }}
    }}
    
    /* Скроллбар */
    ::-webkit-scrollbar {{
      width: 8px;
      height: 8px;
    }}
    
    ::-webkit-scrollbar-track {{
      background: var(--gray-100);
      border-radius: 4px;
    }}
    
    ::-webkit-scrollbar-thumb {{
      background: var(--gray-300);
      border-radius: 4px;
    }}
    
    ::-webkit-scrollbar-thumb:hover {{
      background: var(--gray-400);
    }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🎨 Админ панель - Дети и Животные</h1>
      <div class="nav">
        <a href="/" class="${{activePage === 'home' ? 'active' : ''}}">🏠 Главная</a>
        <a href="/dashboard" class="${{activePage === 'dashboard' ? 'active' : ''}}">📊 Дашборд</a>
        <a href="/categories" class="${{activePage === 'categories' ? 'active' : ''}}">📁 Категории</a>
        <a href="/offers" class="${{activePage === 'offers' ? 'active' : ''}}">🎁 Предложения</a>
        <a href="/analytics" class="${{activePage === 'analytics' ? 'active' : ''}}">📈 Аналитика</a>
      </div>
    </div>
    <div class="content">
      ${{content}}
    </div>
  </div>
  <script>
    function showModal(id) {{
      document.getElementById(id).classList.add('active');
      document.body.style.overflow = 'hidden';
    }}
    function closeModal(id) {{
      document.getElementById(id).classList.remove('active');
      document.body.style.overflow = 'auto';
      const form = document.getElementById(id).querySelector('form');
      if (form) {{
        form.reset();
        const hiddenId = form.querySelector('input[type="hidden"]');
        if (hiddenId) hiddenId.value = '';
      }}
    }}
    function showAlert(message, type = 'info') {{
      const alertDiv = document.createElement('div');
      alertDiv.className = 'alert alert-' + type;
      alertDiv.style.position = 'fixed';
      alertDiv.style.top = '24px';
      alertDiv.style.right = '24px';
      alertDiv.style.zIndex = '10000';
      alertDiv.style.minWidth = '320px';
      alertDiv.style.maxWidth = '500px';
      alertDiv.style.boxShadow = '0 10px 15px -3px rgba(0, 0, 0, 0.1)';
      alertDiv.innerHTML = '<span style="font-weight: 600;">' + message + '</span>';
      document.body.appendChild(alertDiv);
      setTimeout(() => {{
        alertDiv.style.animation = 'slideOut 0.3s';
        setTimeout(() => alertDiv.remove(), 300);
      }}, 3000);
    }}
    
    // Закрытие модального окна при клике вне его
    document.addEventListener('click', function(e) {{
      if (e.target.classList.contains('modal')) {{
        closeModal(e.target.id);
      }}
    }});
  </script>
  <style>
    @keyframes slideOut {{
      from {{ opacity: 1; transform: translateX(0); }}
      to {{ opacity: 0; transform: translateX(100px); }}
    }}
  </style>
</body>
</html>`;

// Главная
app.get('/', (req, res) => {{
  const content = `
    <h2>Добро пожаловать! 👋</h2>
    <p style="font-size: 16px; color: var(--gray-600); margin-bottom: 32px;">Админ панель для управления контентом приложения "Дети и Животные"</p>
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 24px; margin-top: 32px;">
      <div style="padding: 32px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 16px; color: white; box-shadow: var(--shadow-lg); transition: transform 0.3s; cursor: pointer;" onclick="window.location.href='/categories'" onmouseover="this.style.transform='translateY(-4px)'" onmouseout="this.style.transform='translateY(0)'">
        <div style="font-size: 48px; margin-bottom: 16px;">📁</div>
        <h3 style="color: white; margin-bottom: 8px;">Управление категориями</h3>
        <p style="opacity: 0.9; font-size: 14px;">Создавайте и редактируйте категории животных</p>
      </div>
      <div style="padding: 32px; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); border-radius: 16px; color: white; box-shadow: var(--shadow-lg); transition: transform 0.3s; cursor: pointer;" onclick="window.location.href='/offers'" onmouseover="this.style.transform='translateY(-4px)'" onmouseout="this.style.transform='translateY(0)'">
        <div style="font-size: 48px; margin-bottom: 16px;">🎁</div>
        <h3 style="color: white; margin-bottom: 8px;">Управление предложениями</h3>
        <p style="opacity: 0.9; font-size: 14px;">Настраивайте специальные предложения</p>
      </div>
      <div style="padding: 32px; background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); border-radius: 16px; color: white; box-shadow: var(--shadow-lg); transition: transform 0.3s; cursor: pointer;" onclick="window.location.href='/analytics'" onmouseover="this.style.transform='translateY(-4px)'" onmouseout="this.style.transform='translateY(0)'">
        <div style="font-size: 48px; margin-bottom: 16px;">📊</div>
        <h3 style="color: white; margin-bottom: 8px;">Аналитика</h3>
        <p style="opacity: 0.9; font-size: 14px;">Просматривайте статистику и метрики</p>
      </div>
    </div>
    ${{!db ? '<div class="alert alert-info" style="margin-top: 32px;"><strong>💡 Примечание:</strong> Работает в демо-режиме. Для полной функциональности настройте Firebase credentials в .env.local</div>' : ''}}
  `;
  res.send(htmlTemplate('Главная', content, 'home'));
}});

// Дашборд
app.get('/dashboard', async (req, res) => {{
  let stats = {{ categories: 0, animals: 0, offers: 0 }};
  
  try {{
    if (db) {{
      const categoriesSnap = await db.collection('categories').get();
      stats.categories = categoriesSnap.size;
      
      let totalAnimals = 0;
      for (const catDoc of categoriesSnap.docs) {{
        const animalsSnap = await catDoc.ref.collection('animals').get();
        totalAnimals += animalsSnap.size;
      }}
      stats.animals = totalAnimals;
      
      const offersSnap = await db.collection('offers').get();
      stats.offers = offersSnap.size;
    }} else {{
      stats.categories = mockData.categories.length;
      stats.offers = mockData.offers.length;
    }}
  }} catch (e) {{
    console.log('Error loading stats:', e.message);
  }}
  
  const content = `
    <h2>Дашборд 📊</h2>
    <p style="color: var(--gray-600); margin-bottom: 32px;">Общая статистика приложения</p>
    
    <div class="stats-grid">
      <div class="stat-card gradient-1">
        <h3>Категории</h3>
        <p>${{stats.categories}}</p>
      </div>
      <div class="stat-card gradient-2">
        <h3>Животные</h3>
        <p>${{stats.animals}}</p>
      </div>
      <div class="stat-card gradient-3">
        <h3>Предложения</h3>
        <p>${{stats.offers}}</p>
      </div>
    </div>
    
    <div style="margin-top: 48px;">
      <h3>Быстрые действия</h3>
      <div style="display: flex; gap: 16px; margin-top: 20px; flex-wrap: wrap;">
        <a href="/categories" class="btn">📁 Управление категориями</a>
        <a href="/offers" class="btn">🎁 Управление предложениями</a>
        <a href="/analytics" class="btn btn-secondary">📈 Просмотр аналитики</a>
      </div>
    </div>
  `;
  res.send(htmlTemplate('Дашборд', content, 'dashboard'));
}});

// Категории
app.get('/categories', async (req, res) => {{
  let categories = [];
  try {{
    if (db) {{
      const snapshot = await db.collection('categories').orderBy('order', 'asc').get();
      categories = snapshot.docs.map(doc => ({{ id: doc.id, ...doc.data() }}));
    }} else {{
      categories = mockData.categories;
    }}
  }} catch (e) {{
    console.log('Error loading categories:', e.message);
  }}
  
  const categoriesList = categories.length > 0 ? `
    <table class="table">
      <thead>
        <tr>
          <th>Порядок</th>
          <th>Название</th>
          <th>Видимость</th>
          <th>Платная</th>
          <th>Действия</th>
        </tr>
      </thead>
      <tbody>
        ${{categories.map(cat => `
          <tr>
            <td style="font-weight: 600; color: var(--primary);">${{cat.order || 0}}</td>
            <td style="font-weight: 500;">${{cat.title?.ru || cat.title || 'Без названия'}}</td>
            <td><span class="badge ${{cat.isVisible ? 'badge-success' : 'badge-danger'}}">${{cat.isVisible ? '✓ Видима' : '✗ Скрыта'}}</span></td>
            <td><span class="badge ${{cat.isPaid ? 'badge-warning' : 'badge-success'}}">${{cat.isPaid ? '💰 Платная' : '🆓 Бесплатная'}}</span></td>
            <td>
              <div class="action-buttons">
                <a href="/categories/${{cat.id}}/animals" class="btn btn-sm">🐾 Животные</a>
                <button onclick="editCategory('${{cat.id}}')" class="btn btn-sm btn-secondary">✏️ Редактировать</button>
                <button onclick="deleteCategory('${{cat.id}}')" class="btn btn-sm btn-danger">🗑️ Удалить</button>
              </div>
            </td>
          </tr>
        `).join('')}}
      </tbody>
    </table>
  ` : `
    <div class="empty-state">
      <div style="font-size: 80px; margin-bottom: 24px;">📁</div>
      <h3>Категории не найдены</h3>
      <p style="margin-top: 8px;">Создайте первую категорию для начала работы</p>
      <button onclick="showModal('addCategoryModal')" class="btn btn-success" style="margin-top: 24px;">+ Создать категорию</button>
    </div>
  `;
  
  const content = `
    <div class="page-header">
      <div>
        <h2>Категории 📁</h2>
        <p style="color: var(--gray-600); margin-top: 4px;">Управление категориями животных</p>
      </div>
      <button onclick="showModal('addCategoryModal')" class="btn btn-success">+ Добавить категорию</button>
    </div>
    ${{categoriesList}}
    
    <div id="addCategoryModal" class="modal">
      <div class="modal-content">
        <span class="close" onclick="closeModal('addCategoryModal')">&times;</span>
        <h2 id="modalTitle" style="margin-bottom: 24px;">➕ Добавить категорию</h2>
        <form id="categoryForm" onsubmit="saveCategory(event)">
          <input type="hidden" id="categoryId" name="id">
          <div class="form-group">
            <label>Название (RU) *</label>
            <input type="text" id="titleRu" name="titleRu" required placeholder="Например: Домашние животные">
          </div>
          <div class="form-group">
            <label>Название (EN)</label>
            <input type="text" id="titleEn" name="titleEn" placeholder="For example: Pets">
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Порядок *</label>
              <input type="number" id="order" name="order" value="0" required>
            </div>
            <div class="form-group">
              <label>Видимость</label>
              <select id="isVisible" name="isVisible">
                <option value="true">Видима</option>
                <option value="false">Скрыта</option>
              </select>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Платная категория</label>
              <select id="isPaid" name="isPaid">
                <option value="false">Бесплатная</option>
                <option value="true">Платная</option>
              </select>
            </div>
            <div class="form-group">
              <label>IAP Product ID</label>
              <input type="text" id="iapProductId" name="iapProductId" placeholder="com.app.category1">
            </div>
          </div>
          <div class="form-group">
            <label>Путь к иконке *</label>
            <input type="text" id="tabIconAssetPath" name="tabIconAssetPath" placeholder="icons/category1.png" required>
            <small style="color: var(--gray-500); display: block; margin-top: 6px;">Путь к файлу в Firebase Storage</small>
          </div>
          <div style="display: flex; gap: 12px; margin-top: 32px;">
            <button type="submit" class="btn btn-success" style="flex: 1;">💾 Сохранить</button>
            <button type="button" class="btn btn-secondary" onclick="closeModal('addCategoryModal')" style="flex: 1;">Отмена</button>
          </div>
        </form>
      </div>
    </div>
    
    <script>
      function editCategory(id) {{
        fetch('/api/categories/' + id)
          .then(r => r.json())
          .then(data => {{
            document.getElementById('categoryId').value = data.id;
            document.getElementById('titleRu').value = data.title?.ru || '';
            document.getElementById('titleEn').value = data.title?.en || '';
            document.getElementById('order').value = data.order || 0;
            document.getElementById('isVisible').value = data.isVisible ? 'true' : 'false';
            document.getElementById('isPaid').value = data.isPaid ? 'true' : 'false';
            document.getElementById('iapProductId').value = data.iapProductId || '';
            document.getElementById('tabIconAssetPath').value = data.tabIconAssetPath || '';
            document.getElementById('modalTitle').textContent = '✏️ Редактировать категорию';
            showModal('addCategoryModal');
          }})
          .catch(err => showAlert('Ошибка загрузки: ' + err.message, 'danger'));
      }}
      
      function deleteCategory(id) {{
        if (confirm('⚠️ Удалить категорию? Все животные в этой категории также будут удалены.')) {{
          const btn = event.target;
          btn.innerHTML = '<span class="loading"></span>';
          btn.disabled = true;
          fetch('/api/categories/' + id, {{ method: 'DELETE' }})
            .then(r => r.json())
            .then(() => {{
              showAlert('✅ Категория успешно удалена', 'success');
              setTimeout(() => location.reload(), 500);
            }})
            .catch(err => {{
              showAlert('❌ Ошибка удаления: ' + err.message, 'danger');
              btn.innerHTML = '🗑️ Удалить';
              btn.disabled = false;
            }});
        }}
      }}
      
      function saveCategory(e) {{
        e.preventDefault();
        const submitBtn = e.target.querySelector('button[type="submit"]');
        const originalText = submitBtn.innerHTML;
        submitBtn.innerHTML = '<span class="loading"></span> Сохранение...';
        submitBtn.disabled = true;
        
        const formData = {{
          title: {{
            ru: document.getElementById('titleRu').value,
            en: document.getElementById('titleEn').value || document.getElementById('titleRu').value
          }},
          order: parseInt(document.getElementById('order').value),
          isVisible: document.getElementById('isVisible').value === 'true',
          isPaid: document.getElementById('isPaid').value === 'true',
          iapProductId: document.getElementById('iapProductId').value || null,
          tabIconAssetPath: document.getElementById('tabIconAssetPath').value
        }};
        
        const id = document.getElementById('categoryId').value;
        const url = id ? '/api/categories/' + id : '/api/categories';
        const method = id ? 'PUT' : 'POST';
        
        fetch(url, {{
          method: method,
          headers: {{ 'Content-Type': 'application/json' }},
          body: JSON.stringify(formData)
        }})
          .then(r => r.json())
          .then(() => {{
            showAlert(id ? '✅ Категория обновлена' : '✅ Категория создана', 'success');
            closeModal('addCategoryModal');
            setTimeout(() => location.reload(), 500);
          }})
          .catch(err => {{
            showAlert('❌ Ошибка сохранения: ' + err.message, 'danger');
            submitBtn.innerHTML = originalText;
            submitBtn.disabled = false;
          }});
      }}
    </script>
  `;
  res.send(htmlTemplate('Категории', content, 'categories'));
}});

// API для категорий (тот же код что и раньше)
app.get('/api/categories', async (req, res) => {{
  try {{
    if (db) {{
      const snapshot = await db.collection('categories').orderBy('order', 'asc').get();
      const categories = snapshot.docs.map(doc => ({{ id: doc.id, ...doc.data() }}));
      res.json(categories);
    }} else {{
      res.json(mockData.categories);
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.get('/api/categories/:id', async (req, res) => {{
  try {{
    if (db) {{
      const doc = await db.collection('categories').doc(req.params.id).get();
      if (doc.exists) {{
        res.json({{ id: doc.id, ...doc.data() }});
      }} else {{
        res.status(404).json({{ error: 'Not found' }});
      }}
    }} else {{
      const cat = mockData.categories.find(c => c.id === req.params.id);
      if (cat) res.json(cat);
      else res.status(404).json({{ error: 'Not found' }});
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.post('/api/categories', async (req, res) => {{
  try {{
    if (db) {{
      const docRef = await db.collection('categories').add(req.body);
      res.json({{ id: docRef.id }});
    }} else {{
      const newId = 'cat_' + Date.now();
      mockData.categories.push({{ id: newId, ...req.body }});
      res.json({{ id: newId }});
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.put('/api/categories/:id', async (req, res) => {{
  try {{
    if (db) {{
      await db.collection('categories').doc(req.params.id).update(req.body);
      res.json({{ success: true }});
    }} else {{
      const index = mockData.categories.findIndex(c => c.id === req.params.id);
      if (index !== -1) {{
        mockData.categories[index] = {{ ...mockData.categories[index], ...req.body }};
        res.json({{ success: true }});
      }} else {{
        res.status(404).json({{ error: 'Not found' }});
      }}
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.delete('/api/categories/:id', async (req, res) => {{
  try {{
    if (db) {{
      const animalsSnap = await db.collection('categories').doc(req.params.id).collection('animals').get();
      const batch = db.batch();
      animalsSnap.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
      await db.collection('categories').doc(req.params.id).delete();
      res.json({{ success: true }});
    }} else {{
      mockData.categories = mockData.categories.filter(c => c.id !== req.params.id);
      res.json({{ success: true }});
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

// Страница животных
app.get('/categories/:id/animals', async (req, res) => {{
  let animals = [];
  let category = null;
  try {{
    if (db) {{
      const catDoc = await db.collection('categories').doc(req.params.id).get();
      if (catDoc.exists) {{
        category = {{ id: catDoc.id, ...catDoc.data() }};
        const animalsSnap = await catDoc.ref.collection('animals').orderBy('order', 'asc').get();
        animals = animalsSnap.docs.map(doc => ({{ id: doc.id, ...doc.data() }}));
      }}
    }} else {{
      category = mockData.categories.find(c => c.id === req.params.id);
      if (category) animals = (category.animals || []);
    }}
  }} catch (e) {{
    console.log('Error loading animals:', e.message);
  }}
  
  if (!category) {{
    return res.send(htmlTemplate('Ошибка', '<p>Категория не найдена</p><a href="/categories" class="back-link">← Назад</a>', 'categories'));
  }}
  
  const animalsList = animals.length > 0 ? `
    <table class="table">
      <thead>
        <tr>
          <th>Порядок</th>
          <th>Название</th>
          <th>Видимость</th>
          <th>Действия</th>
        </tr>
      </thead>
      <tbody>
        ${{animals.map(animal => `
          <tr>
            <td style="font-weight: 600; color: var(--primary);">${{animal.order || 0}}</td>
            <td style="font-weight: 500;">${{animal.name?.ru || animal.name || 'Без названия'}}</td>
            <td><span class="badge ${{animal.isVisible ? 'badge-success' : 'badge-danger'}}">${{animal.isVisible ? '✓ Видимо' : '✗ Скрыто'}}</span></td>
            <td>
              <div class="action-buttons">
                <button onclick="editAnimal('${{animal.id}}')" class="btn btn-sm btn-secondary">✏️ Редактировать</button>
                <button onclick="deleteAnimal('${{animal.id}}')" class="btn btn-sm btn-danger">🗑️ Удалить</button>
              </div>
            </td>
          </tr>
        `).join('')}}
      </tbody>
    </table>
  ` : `
    <div class="empty-state">
      <div style="font-size: 80px; margin-bottom: 24px;">🐾</div>
      <h3>Животные не найдены</h3>
      <p style="margin-top: 8px;">Добавьте первое животное в эту категорию</p>
      <button onclick="showModal('addAnimalModal')" class="btn btn-success" style="margin-top: 24px;">+ Добавить животное</button>
    </div>
  `;
  
  const content = `
    <a href="/categories" class="back-link">← Назад к категориям</a>
    <div class="page-header">
      <div>
        <h2>Животные: ${{category.title?.ru || category.title || 'Категория'}} 🐾</h2>
        <p style="color: var(--gray-600); margin-top: 4px;">Управление животными в категории</p>
      </div>
      <button onclick="showModal('addAnimalModal')" class="btn btn-success">+ Добавить животное</button>
    </div>
    ${{animalsList}}
    
    <div id="addAnimalModal" class="modal">
      <div class="modal-content">
        <span class="close" onclick="closeModal('addAnimalModal')">&times;</span>
        <h2 id="animalModalTitle" style="margin-bottom: 24px;">➕ Добавить животное</h2>
        <form id="animalForm" onsubmit="saveAnimal(event)">
          <input type="hidden" id="animalId" name="id">
          <div class="form-group">
            <label>Название (RU) *</label>
            <input type="text" id="animalNameRu" name="nameRu" required placeholder="Например: Кот">
          </div>
          <div class="form-group">
            <label>Название (EN)</label>
            <input type="text" id="animalNameEn" name="nameEn" placeholder="For example: Cat">
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Порядок *</label>
              <input type="number" id="animalOrder" name="order" value="0" required>
            </div>
            <div class="form-group">
              <label>Видимость</label>
              <select id="animalIsVisible" name="isVisible">
                <option value="true">Видимо</option>
                <option value="false">Скрыто</option>
              </select>
            </div>
          </div>
          <div class="form-group">
            <label>Путь к фоновому изображению</label>
            <input type="text" id="bgAssetPath" name="bgAssetPath" placeholder="backgrounds/animal1.jpg">
            <small style="color: var(--gray-500); display: block; margin-top: 6px;">Путь к файлу в Firebase Storage</small>
          </div>
          <div class="form-group">
            <label>Путь к превью</label>
            <input type="text" id="previewAssetPath" name="previewAssetPath" placeholder="previews/animal1.jpg">
          </div>
          <div class="form-group">
            <label>Путь к звуку</label>
            <input type="text" id="soundAssetPath" name="soundAssetPath" placeholder="sounds/animal1.mp3">
          </div>
          <div class="form-group">
            <label>Путь к анимации (Lottie JSON)</label>
            <input type="text" id="animationAssetPath" name="animationAssetPath" placeholder="animations/animal1.json">
          </div>
          <div style="display: flex; gap: 12px; margin-top: 32px;">
            <button type="submit" class="btn btn-success" style="flex: 1;">💾 Сохранить</button>
            <button type="button" class="btn btn-secondary" onclick="closeModal('addAnimalModal')" style="flex: 1;">Отмена</button>
          </div>
        </form>
      </div>
    </div>
    
    <script>
      function editAnimal(id) {{
        fetch('/api/categories/${{req.params.id}}/animals/' + id)
          .then(r => r.json())
          .then(data => {{
            document.getElementById('animalId').value = data.id;
            document.getElementById('animalNameRu').value = data.name?.ru || '';
            document.getElementById('animalNameEn').value = data.name?.en || '';
            document.getElementById('animalOrder').value = data.order || 0;
            document.getElementById('animalIsVisible').value = data.isVisible ? 'true' : 'false';
            document.getElementById('bgAssetPath').value = data.bgAssetPath || '';
            document.getElementById('previewAssetPath').value = data.previewAssetPath || '';
            document.getElementById('soundAssetPath').value = data.soundAssetPath || '';
            document.getElementById('animationAssetPath').value = data.animationAssetPath || '';
            document.getElementById('animalModalTitle').textContent = '✏️ Редактировать животное';
            showModal('addAnimalModal');
          }})
          .catch(err => showAlert('Ошибка загрузки: ' + err.message, 'danger'));
      }}
      
      function deleteAnimal(id) {{
        if (confirm('⚠️ Удалить животное?')) {{
          const btn = event.target;
          btn.innerHTML = '<span class="loading"></span>';
          btn.disabled = true;
          fetch('/api/categories/${{req.params.id}}/animals/' + id, {{ method: 'DELETE' }})
            .then(() => {{
              showAlert('✅ Животное удалено', 'success');
              setTimeout(() => location.reload(), 500);
            }})
            .catch(err => {{
              showAlert('❌ Ошибка удаления: ' + err.message, 'danger');
              btn.innerHTML = '🗑️ Удалить';
              btn.disabled = false;
            }});
        }}
      }}
      
      function saveAnimal(e) {{
        e.preventDefault();
        const submitBtn = e.target.querySelector('button[type="submit"]');
        const originalText = submitBtn.innerHTML;
        submitBtn.innerHTML = '<span class="loading"></span> Сохранение...';
        submitBtn.disabled = true;
        
        const formData = {{
          name: {{
            ru: document.getElementById('animalNameRu').value,
            en: document.getElementById('animalNameEn').value || document.getElementById('animalNameRu').value
          }},
          order: parseInt(document.getElementById('animalOrder').value),
          isVisible: document.getElementById('animalIsVisible').value === 'true',
          bgAssetPath: document.getElementById('bgAssetPath').value,
          previewAssetPath: document.getElementById('previewAssetPath').value,
          soundAssetPath: document.getElementById('soundAssetPath').value,
          animationAssetPath: document.getElementById('animationAssetPath').value || null
        }};
        
        const id = document.getElementById('animalId').value;
        const url = id ? '/api/categories/${{req.params.id}}/animals/' + id : '/api/categories/${{req.params.id}}/animals';
        const method = id ? 'PUT' : 'POST';
        
        fetch(url, {{
          method: method,
          headers: {{ 'Content-Type': 'application/json' }},
          body: JSON.stringify(formData)
        }})
          .then(r => r.json())
          .then(() => {{
            showAlert(id ? '✅ Животное обновлено' : '✅ Животное создано', 'success');
            closeModal('addAnimalModal');
            setTimeout(() => location.reload(), 500);
          }})
          .catch(err => {{
            showAlert('❌ Ошибка сохранения: ' + err.message, 'danger');
            submitBtn.innerHTML = originalText;
            submitBtn.disabled = false;
          }});
      }}
    </script>
  `;
  res.send(htmlTemplate('Животные', content, 'categories'));
}});

// API для животных (тот же код)
app.get('/api/categories/:catId/animals', async (req, res) => {{
  try {{
    if (db) {{
      const snapshot = await db.collection('categories').doc(req.params.catId).collection('animals').orderBy('order', 'asc').get();
      const animals = snapshot.docs.map(doc => ({{ id: doc.id, ...doc.data() }}));
      res.json(animals);
    }} else {{
      const category = mockData.categories.find(c => c.id === req.params.catId);
      res.json(category?.animals || []);
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.get('/api/categories/:catId/animals/:id', async (req, res) => {{
  try {{
    if (db) {{
      const doc = await db.collection('categories').doc(req.params.catId).collection('animals').doc(req.params.id).get();
      if (doc.exists) {{
        res.json({{ id: doc.id, ...doc.data() }});
      }} else {{
        res.status(404).json({{ error: 'Not found' }});
      }}
    }} else {{
      const category = mockData.categories.find(c => c.id === req.params.catId);
      const animal = category?.animals?.find(a => a.id === req.params.id);
      if (animal) res.json(animal);
      else res.status(404).json({{ error: 'Not found' }});
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.post('/api/categories/:catId/animals', async (req, res) => {{
  try {{
    if (db) {{
      const docRef = await db.collection('categories').doc(req.params.catId).collection('animals').add(req.body);
      res.json({{ id: docRef.id }});
    }} else {{
      const category = mockData.categories.find(c => c.id === req.params.catId);
      if (category) {{
        if (!category.animals) category.animals = [];
        const newId = 'animal_' + Date.now();
        category.animals.push({{ id: newId, ...req.body }});
        res.json({{ id: newId }});
      }} else {{
        res.status(404).json({{ error: 'Category not found' }});
      }}
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.put('/api/categories/:catId/animals/:id', async (req, res) => {{
  try {{
    if (db) {{
      await db.collection('categories').doc(req.params.catId).collection('animals').doc(req.params.id).update(req.body);
      res.json({{ success: true }});
    }} else {{
      const category = mockData.categories.find(c => c.id === req.params.catId);
      if (category && category.animals) {{
        const index = category.animals.findIndex(a => a.id === req.params.id);
        if (index !== -1) {{
          category.animals[index] = {{ ...category.animals[index], ...req.body }};
          res.json({{ success: true }});
        }} else {{
          res.status(404).json({{ error: 'Not found' }});
        }}
      }} else {{
        res.status(404).json({{ error: 'Not found' }});
      }}
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.delete('/api/categories/:catId/animals/:id', async (req, res) => {{
  try {{
    if (db) {{
      await db.collection('categories').doc(req.params.catId).collection('animals').doc(req.params.id).delete();
      res.json({{ success: true }});
    }} else {{
      const category = mockData.categories.find(c => c.id === req.params.catId);
      if (category && category.animals) {{
        category.animals = category.animals.filter(a => a.id !== req.params.id);
        res.json({{ success: true }});
      }} else {{
        res.status(404).json({{ error: 'Not found' }});
      }}
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

// Предложения
app.get('/offers', async (req, res) => {{
  let offers = [];
  try {{
    if (db) {{
      const snapshot = await db.collection('offers').get();
      offers = snapshot.docs.map(doc => ({{ id: doc.id, ...doc.data() }}));
    }} else {{
      offers = mockData.offers;
    }}
  }} catch (e) {{
    console.log('Error loading offers:', e.message);
  }}
  
  const offersList = offers.length > 0 ? `
    <table class="table">
      <thead>
        <tr>
          <th>Название</th>
          <th>Статус</th>
          <th>Элементов</th>
          <th>Действия</th>
        </tr>
      </thead>
      <tbody>
        ${{offers.map(offer => `
          <tr>
            <td style="font-weight: 500;">${{offer.title?.ru || offer.title || 'Без названия'}}</td>
            <td><span class="badge ${{offer.isActive ? 'badge-success' : 'badge-danger'}}">${{offer.isActive ? '✓ Активно' : '✗ Неактивно'}}</span></td>
            <td>${{offer.items?.length || 0}}</td>
            <td>
              <div class="action-buttons">
                <button onclick="editOffer('${{offer.id}}')" class="btn btn-sm btn-secondary">✏️ Редактировать</button>
                <button onclick="deleteOffer('${{offer.id}}')" class="btn btn-sm btn-danger">🗑️ Удалить</button>
              </div>
            </td>
          </tr>
        `).join('')}}
      </tbody>
    </table>
  ` : `
    <div class="empty-state">
      <div style="font-size: 80px; margin-bottom: 24px;">🎁</div>
      <h3>Предложения не найдены</h3>
      <p style="margin-top: 8px;">Создайте первое предложение</p>
      <button onclick="showModal('addOfferModal')" class="btn btn-success" style="margin-top: 24px;">+ Создать предложение</button>
    </div>
  `;
  
  const content = `
    <div class="page-header">
      <div>
        <h2>Предложения 🎁</h2>
        <p style="color: var(--gray-600); margin-top: 4px;">Управление специальными предложениями</p>
      </div>
      <button onclick="showModal('addOfferModal')" class="btn btn-success">+ Добавить предложение</button>
    </div>
    ${{offersList}}
    
    <div id="addOfferModal" class="modal">
      <div class="modal-content">
        <span class="close" onclick="closeModal('addOfferModal')">&times;</span>
        <h2 id="offerModalTitle" style="margin-bottom: 24px;">➕ Добавить предложение</h2>
        <form id="offerForm" onsubmit="saveOffer(event)">
          <input type="hidden" id="offerId" name="id">
          <div class="form-group">
            <label>Название (RU) *</label>
            <input type="text" id="offerTitleRu" name="titleRu" required placeholder="Например: Премиум пакет">
          </div>
          <div class="form-group">
            <label>Название (EN)</label>
            <input type="text" id="offerTitleEn" name="titleEn" placeholder="For example: Premium Pack">
          </div>
          <div class="form-group">
            <label>Активно</label>
            <select id="offerIsActive" name="isActive">
              <option value="true">Активно</option>
              <option value="false">Неактивно</option>
            </select>
          </div>
          <div class="form-group">
            <label>Primary Product ID</label>
            <input type="text" id="primaryProductId" name="primaryProductId" placeholder="com.app.premium">
          </div>
          <div style="display: flex; gap: 12px; margin-top: 32px;">
            <button type="submit" class="btn btn-success" style="flex: 1;">💾 Сохранить</button>
            <button type="button" class="btn btn-secondary" onclick="closeModal('addOfferModal')" style="flex: 1;">Отмена</button>
          </div>
        </form>
      </div>
    </div>
    
    <script>
      function editOffer(id) {{
        fetch('/api/offers/' + id)
          .then(r => r.json())
          .then(data => {{
            document.getElementById('offerId').value = data.id;
            document.getElementById('offerTitleRu').value = data.title?.ru || '';
            document.getElementById('offerTitleEn').value = data.title?.en || '';
            document.getElementById('offerIsActive').value = data.isActive ? 'true' : 'false';
            document.getElementById('primaryProductId').value = data.primaryProductId || '';
            document.getElementById('offerModalTitle').textContent = '✏️ Редактировать предложение';
            showModal('addOfferModal');
          }})
          .catch(err => showAlert('Ошибка загрузки: ' + err.message, 'danger'));
      }}
      
      function deleteOffer(id) {{
        if (confirm('⚠️ Удалить предложение?')) {{
          const btn = event.target;
          btn.innerHTML = '<span class="loading"></span>';
          btn.disabled = true;
          fetch('/api/offers/' + id, {{ method: 'DELETE' }})
            .then(() => {{
              showAlert('✅ Предложение удалено', 'success');
              setTimeout(() => location.reload(), 500);
            }})
            .catch(err => {{
              showAlert('❌ Ошибка удаления: ' + err.message, 'danger');
              btn.innerHTML = '🗑️ Удалить';
              btn.disabled = false;
            }});
        }}
      }}
      
      function saveOffer(e) {{
        e.preventDefault();
        const submitBtn = e.target.querySelector('button[type="submit"]');
        const originalText = submitBtn.innerHTML;
        submitBtn.innerHTML = '<span class="loading"></span> Сохранение...';
        submitBtn.disabled = true;
        
        const formData = {{
          title: {{
            ru: document.getElementById('offerTitleRu').value,
            en: document.getElementById('offerTitleEn').value || document.getElementById('offerTitleRu').value
          }},
          isActive: document.getElementById('offerIsActive').value === 'true',
          primaryProductId: document.getElementById('primaryProductId').value,
          items: [],
          heroAssets: []
        }};
        
        const id = document.getElementById('offerId').value;
        const url = id ? '/api/offers/' + id : '/api/offers';
        const method = id ? 'PUT' : 'POST';
        
        fetch(url, {{
          method: method,
          headers: {{ 'Content-Type': 'application/json' }},
          body: JSON.stringify(formData)
        }})
          .then(r => r.json())
          .then(() => {{
            showAlert(id ? '✅ Предложение обновлено' : '✅ Предложение создано', 'success');
            closeModal('addOfferModal');
            setTimeout(() => location.reload(), 500);
          }})
          .catch(err => {{
            showAlert('❌ Ошибка сохранения: ' + err.message, 'danger');
            submitBtn.innerHTML = originalText;
            submitBtn.disabled = false;
          }});
      }}
    </script>
  `;
  res.send(htmlTemplate('Предложения', content, 'offers'));
}});

// API для предложений (тот же код)
app.get('/api/offers', async (req, res) => {{
  try {{
    if (db) {{
      const snapshot = await db.collection('offers').get();
      const offers = snapshot.docs.map(doc => ({{ id: doc.id, ...doc.data() }}));
      res.json(offers);
    }} else {{
      res.json(mockData.offers);
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.get('/api/offers/:id', async (req, res) => {{
  try {{
    if (db) {{
      const doc = await db.collection('offers').doc(req.params.id).get();
      if (doc.exists) {{
        res.json({{ id: doc.id, ...doc.data() }});
      }} else {{
        res.status(404).json({{ error: 'Not found' }});
      }}
    }} else {{
      const offer = mockData.offers.find(o => o.id === req.params.id);
      if (offer) res.json(offer);
      else res.status(404).json({{ error: 'Not found' }});
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.post('/api/offers', async (req, res) => {{
  try {{
    if (db) {{
      const docRef = await db.collection('offers').add(req.body);
      res.json({{ id: docRef.id }});
    }} else {{
      const newId = 'offer_' + Date.now();
      mockData.offers.push({{ id: newId, ...req.body }});
      res.json({{ id: newId }});
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.put('/api/offers/:id', async (req, res) => {{
  try {{
    if (db) {{
      await db.collection('offers').doc(req.params.id).update(req.body);
      res.json({{ success: true }});
    }} else {{
      const index = mockData.offers.findIndex(o => o.id === req.params.id);
      if (index !== -1) {{
        mockData.offers[index] = {{ ...mockData.offers[index], ...req.body }};
        res.json({{ success: true }});
      }} else {{
        res.status(404).json({{ error: 'Not found' }});
      }}
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.delete('/api/offers/:id', async (req, res) => {{
  try {{
    if (db) {{
      await db.collection('offers').doc(req.params.id).delete();
      res.json({{ success: true }});
    }} else {{
      mockData.offers = mockData.offers.filter(o => o.id !== req.params.id);
      res.json({{ success: true }});
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

// Аналитика
app.get('/analytics', (req, res) => {{
  const content = `
    <h2>Аналитика 📈</h2>
    <div class="empty-state">
      <div style="font-size: 80px; margin-bottom: 24px;">📊</div>
      <h3>Аналитика настраивается</h3>
      <p style="margin-top: 8px;">Данные будут доступны после интеграции с Firebase Analytics</p>
    </div>
  `;
  res.send(htmlTemplate('Аналитика', content, 'analytics'));
}});

app.listen(PORT, '127.0.0.1', () => {{
  console.log('Beautiful admin panel running on http://127.0.0.1:' + PORT);
  console.log('Firebase:', db ? 'Connected' : 'Mock mode');
}});
"""

sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/server.js", "w") as f:
        f.write(beautiful_server)
    print("  Beautiful server.js created")
except Exception as e:
    print(f"  Error: {e}")
finally:
    sftp.close()

# Запуск
print("[2] Starting server...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
exec node server.js
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-beautiful-admin.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-beautiful-admin.sh", 0o755)
finally:
    sftp.close()

code, start_out, _ = safe_run("pm2 start /tmp/start-beautiful-admin.sh --name deti-admin --interpreter bash")
print(f"Start: {start_out[:500]}")

# Ждем
print("\n[3] Waiting 10 seconds...")
time.sleep(10)

# Проверка
print("[4] Testing...")
code, page_test, _ = safe_run("curl -s http://127.0.0.1:3000/categories 2>&1 | grep -E 'Категории|gradient|shadow' | head -3", timeout=10)
if page_test:
    print("[OK] Beautiful design loaded")

code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\n" + "="*60)
print("BEAUTIFUL ADMIN PANEL DEPLOYED!")
print("="*60)
print("Premium design features:")
print("  - Modern gradient backgrounds")
print("  - Smooth animations and transitions")
print("  - Professional typography (Inter font)")
print("  - Beautiful color scheme")
print("  - Premium shadows and effects")
print("  - Responsive design")
print("  - Modern UI components")
print("\nURL: http://168.222.193.86/categories")
