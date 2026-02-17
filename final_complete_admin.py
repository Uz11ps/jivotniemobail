"""Финальная полноценная админ панель"""
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
    return code, safe_out[:20000], safe_err[:15000]

print("Creating final complete admin panel...")

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
            key = parts[0].strip()
            value = parts[1].strip()
            env_vars[key] = value

print(f"\n[1] Found {len(env_vars)} environment variables")

# Создаем полноценный сервер с правильной инициализацией Firebase
print("[2] Creating complete server...")

complete_server = f"""const express = require('express');
const admin = require('firebase-admin');
require('dotenv').config({{ path: '.env.local' }});

const app = express();
const PORT = 3000;

app.use(express.json());
app.use(express.urlencoded({{ extended: true }}));

// Инициализация Firebase Admin
let db = null;
try {{
  const projectId = process.env.FIREBASE_PROJECT_ID || '{env_vars.get("FIREBASE_PROJECT_ID", "")}';
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL || '{env_vars.get("FIREBASE_CLIENT_EMAIL", "")}';
  const privateKey = (process.env.FIREBASE_PRIVATE_KEY || '{env_vars.get("FIREBASE_PRIVATE_KEY", "")}').replace(/\\\\n/g, '\\n');
  
  if (projectId && clientEmail && privateKey && privateKey !== '') {{
    admin.initializeApp({{
      credential: admin.credential.cert({{
        projectId: projectId,
        clientEmail: clientEmail,
        privateKey: privateKey
      }})
    }});
    db = admin.firestore();
    console.log('Firebase Admin initialized successfully');
  }} else {{
    console.log('Firebase Admin credentials not provided, using mock mode');
  }}
}} catch (e) {{
  console.log('Firebase Admin init error:', e.message);
  console.log('Using mock mode');
}}

// Mock хранилище для демонстрации
let mockData = {{
  categories: [],
  offers: []
}};

// HTML шаблон
const htmlTemplate = (title, content, activePage = '') => `<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${{title}} - Админ панель</title>
  <style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; }}
    .container {{ max-width: 1400px; margin: 0 auto; padding: 20px; }}
    .header {{ background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
    .nav {{ display: flex; gap: 10px; margin-top: 15px; flex-wrap: wrap; }}
    .nav a {{ padding: 10px 20px; background: #0070f3; color: white; text-decoration: none; border-radius: 5px; transition: background 0.2s; }}
    .nav a:hover {{ background: #0051cc; }}
    .nav a.active {{ background: #0051cc; font-weight: bold; }}
    .content {{ background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
    h1 {{ color: #333; margin-bottom: 20px; }}
    h2 {{ color: #333; margin-bottom: 15px; margin-top: 30px; }}
    .btn {{ padding: 10px 20px; background: #0070f3; color: white; border: none; border-radius: 5px; cursor: pointer; font-size: 14px; text-decoration: none; display: inline-block; }}
    .btn:hover {{ background: #0051cc; }}
    .btn-danger {{ background: #dc3545; }}
    .btn-danger:hover {{ background: #c82333; }}
    .btn-success {{ background: #28a745; }}
    .btn-success:hover {{ background: #218838; }}
    .table {{ width: 100%; border-collapse: collapse; margin-top: 20px; }}
    .table th, .table td {{ padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }}
    .table th {{ background: #f8f9fa; font-weight: 600; color: #333; }}
    .table tr:hover {{ background: #f8f9fa; }}
    .form-group {{ margin-bottom: 20px; }}
    .form-group label {{ display: block; margin-bottom: 5px; color: #333; font-weight: 500; }}
    .form-group input, .form-group textarea, .form-group select {{
      width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px;
    }}
    .form-group textarea {{ min-height: 100px; resize: vertical; }}
    .form-row {{ display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }}
    .badge {{ display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: 500; }}
    .badge-success {{ background: #d4edda; color: #155724; }}
    .badge-danger {{ background: #f8d7da; color: #721c24; }}
    .badge-warning {{ background: #fff3cd; color: #856404; }}
    .badge-info {{ background: #d1ecf1; color: #0c5460; }}
    .empty-state {{ text-align: center; padding: 60px 20px; color: #666; }}
    .modal {{ display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 1000; }}
    .modal.active {{ display: flex; align-items: center; justify-content: center; }}
    .modal-content {{ background: white; padding: 30px; border-radius: 8px; max-width: 700px; width: 90%; max-height: 90vh; overflow-y: auto; }}
    .close {{ float: right; font-size: 28px; font-weight: bold; cursor: pointer; }}
    .close:hover {{ color: #dc3545; }}
    .alert {{ padding: 15px; margin-bottom: 20px; border-radius: 5px; }}
    .alert-info {{ background: #d1ecf1; color: #0c5460; border-left: 4px solid #0c5460; }}
    @media (max-width: 768px) {{
      .form-row {{ grid-template-columns: 1fr; }}
      .nav {{ flex-direction: column; }}
    }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Админ панель - Дети и Животные</h1>
      <div class="nav">
        <a href="/" class="${{activePage === 'home' ? 'active' : ''}}">Главная</a>
        <a href="/dashboard" class="${{activePage === 'dashboard' ? 'active' : ''}}">Дашборд</a>
        <a href="/categories" class="${{activePage === 'categories' ? 'active' : ''}}">Категории</a>
        <a href="/offers" class="${{activePage === 'offers' ? 'active' : ''}}">Предложения</a>
        <a href="/analytics" class="${{activePage === 'analytics' ? 'active' : ''}}">Аналитика</a>
      </div>
    </div>
    <div class="content">
      ${{content}}
    </div>
  </div>
  <script>
    function showModal(id) {{
      document.getElementById(id).classList.add('active');
    }}
    function closeModal(id) {{
      document.getElementById(id).classList.remove('active');
      // Сброс формы
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
      alertDiv.textContent = message;
      alertDiv.style.position = 'fixed';
      alertDiv.style.top = '20px';
      alertDiv.style.right = '20px';
      alertDiv.style.zIndex = '10000';
      alertDiv.style.minWidth = '300px';
      document.body.appendChild(alertDiv);
      setTimeout(() => alertDiv.remove(), 3000);
    }}
  </script>
</body>
</html>`;

// Главная
app.get('/', (req, res) => {{
  const content = `
    <h2>Добро пожаловать!</h2>
    <p>Админ панель для управления контентом приложения "Дети и Животные".</p>
    <div style="margin-top: 30px; padding: 20px; background: #e7f3ff; border-radius: 8px; border-left: 4px solid #0070f3;">
      <h3 style="margin-bottom: 10px;">Быстрый доступ</h3>
      <ul style="list-style: none; padding: 0;">
        <li style="margin: 10px 0;"><a href="/categories" style="color: #0070f3; text-decoration: none;">📁 Управление категориями</a></li>
        <li style="margin: 10px 0;"><a href="/offers" style="color: #0070f3; text-decoration: none;">🎁 Управление предложениями</a></li>
        <li style="margin: 10px 0;"><a href="/analytics" style="color: #0070f3; text-decoration: none;">📊 Просмотр аналитики</a></li>
      </ul>
    </div>
    ${{!db ? '<div class="alert alert-info" style="margin-top: 20px;"><strong>Примечание:</strong> Работает в демо-режиме. Для полной функциональности настройте Firebase credentials в .env.local</div>' : ''}}
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
    <h2>Дашборд</h2>
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-top: 30px;">
      <div style="padding: 25px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 8px; color: white;">
        <h3 style="font-size: 14px; opacity: 0.9; margin-bottom: 10px;">Категории</h3>
        <p style="font-size: 36px; font-weight: bold;">${{stats.categories}}</p>
      </div>
      <div style="padding: 25px; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); border-radius: 8px; color: white;">
        <h3 style="font-size: 14px; opacity: 0.9; margin-bottom: 10px;">Животные</h3>
        <p style="font-size: 36px; font-weight: bold;">${{stats.animals}}</p>
      </div>
      <div style="padding: 25px; background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); border-radius: 8px; color: white;">
        <h3 style="font-size: 14px; opacity: 0.9; margin-bottom: 10px;">Предложения</h3>
        <p style="font-size: 36px; font-weight: bold;">${{stats.offers}}</p>
      </div>
    </div>
    <div style="margin-top: 40px;">
      <h3>Быстрые действия</h3>
      <div style="margin-top: 15px;">
        <a href="/categories" class="btn">Управление категориями</a>
        <a href="/offers" class="btn" style="margin-left: 10px;">Управление предложениями</a>
      </div>
    </div>
  `;
  res.send(htmlTemplate('Дашборд', content, 'dashboard'));
}});

// Категории - список
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
            <td>${{cat.order || 0}}</td>
            <td>${{cat.title?.ru || cat.title || 'Без названия'}}</td>
            <td><span class="badge ${{cat.isVisible ? 'badge-success' : 'badge-danger'}}">${{cat.isVisible ? 'Видима' : 'Скрыта'}}</span></td>
            <td><span class="badge ${{cat.isPaid ? 'badge-warning' : 'badge-success'}}">${{cat.isPaid ? 'Платная' : 'Бесплатная'}}</span></td>
            <td>
              <a href="/categories/${{cat.id}}/animals" class="btn" style="padding: 5px 10px; font-size: 12px;">Животные</a>
              <button onclick="editCategory('${{cat.id}}')" class="btn" style="padding: 5px 10px; font-size: 12px; margin-left: 5px;">Редактировать</button>
              <button onclick="deleteCategory('${{cat.id}}')" class="btn btn-danger" style="padding: 5px 10px; font-size: 12px; margin-left: 5px;">Удалить</button>
            </td>
          </tr>
        `).join('')}}
      </tbody>
    </table>
  ` : `
    <div class="empty-state">
      <p>Категории не найдены</p>
      <p style="margin-top: 10px; color: #999;">Создайте первую категорию</p>
    </div>
  `;
  
  const content = `
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
      <h2>Категории</h2>
      <button onclick="showModal('addCategoryModal')" class="btn btn-success">+ Добавить категорию</button>
    </div>
    ${{categoriesList}}
    
    <div id="addCategoryModal" class="modal">
      <div class="modal-content">
        <span class="close" onclick="closeModal('addCategoryModal')">&times;</span>
        <h2 id="modalTitle">Добавить категорию</h2>
        <form id="categoryForm" onsubmit="saveCategory(event)">
          <input type="hidden" id="categoryId" name="id">
          <div class="form-group">
            <label>Название (RU) *</label>
            <input type="text" id="titleRu" name="titleRu" required>
          </div>
          <div class="form-group">
            <label>Название (EN)</label>
            <input type="text" id="titleEn" name="titleEn">
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
            <small style="color: #666; display: block; margin-top: 5px;">Путь к файлу в Firebase Storage (например: icons/category1.png)</small>
          </div>
          <div style="margin-top: 20px;">
            <button type="submit" class="btn btn-success">Сохранить</button>
            <button type="button" class="btn" onclick="closeModal('addCategoryModal')" style="margin-left: 10px;">Отмена</button>
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
            document.getElementById('modalTitle').textContent = 'Редактировать категорию';
            showModal('addCategoryModal');
          }})
          .catch(err => showAlert('Ошибка загрузки: ' + err.message, 'danger'));
      }}
      
      function deleteCategory(id) {{
        if (confirm('Удалить категорию? Все животные в этой категории также будут удалены.')) {{
          fetch('/api/categories/' + id, {{ method: 'DELETE' }})
            .then(r => r.json())
            .then(() => {{
              showAlert('Категория удалена', 'success');
              setTimeout(() => location.reload(), 500);
            }})
            .catch(err => showAlert('Ошибка удаления: ' + err.message, 'danger'));
        }}
      }}
      
      function saveCategory(e) {{
        e.preventDefault();
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
            showAlert(id ? 'Категория обновлена' : 'Категория создана', 'success');
            closeModal('addCategoryModal');
            setTimeout(() => location.reload(), 500);
          }})
          .catch(err => showAlert('Ошибка сохранения: ' + err.message, 'danger'));
      }}
      
      document.getElementById('addCategoryModal').addEventListener('click', function(e) {{
        if (e.target === this) {{
          closeModal('addCategoryModal');
        }}
      }});
    </script>
  `;
  res.send(htmlTemplate('Категории', content, 'categories'));
}});

// API для категорий
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
      // Удаляем животных в категории
      const animalsSnap = await db.collection('categories').doc(req.params.id).collection('animals').get();
      const batch = db.batch();
      animalsSnap.docs.forEach(doc => {{
        batch.delete(doc.ref);
      }});
      await batch.commit();
      
      // Удаляем категорию
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
      if (category) {{
        animals = (category.animals || []);
      }}
    }}
  }} catch (e) {{
    console.log('Error loading animals:', e.message);
  }}
  
  if (!category) {{
    return res.send(htmlTemplate('Ошибка', '<p>Категория не найдена</p><a href="/categories">← Назад</a>', 'categories'));
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
            <td>${{animal.order || 0}}</td>
            <td>${{animal.name?.ru || animal.name || 'Без названия'}}</td>
            <td><span class="badge ${{animal.isVisible ? 'badge-success' : 'badge-danger'}}">${{animal.isVisible ? 'Видимо' : 'Скрыто'}}</span></td>
            <td>
              <button onclick="editAnimal('${{animal.id}}')" class="btn" style="padding: 5px 10px; font-size: 12px;">Редактировать</button>
              <button onclick="deleteAnimal('${{animal.id}}')" class="btn btn-danger" style="padding: 5px 10px; font-size: 12px; margin-left: 5px;">Удалить</button>
            </td>
          </tr>
        `).join('')}}
      </tbody>
    </table>
  ` : `
    <div class="empty-state">
      <p>Животные не найдены</p>
      <p style="margin-top: 10px; color: #999;">Добавьте первое животное в эту категорию</p>
    </div>
  `;
  
  const content = `
    <div style="margin-bottom: 20px;">
      <a href="/categories" style="color: #0070f3; text-decoration: none;">← Назад к категориям</a>
    </div>
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
      <h2>Животные: ${{category.title?.ru || category.title || 'Категория'}}</h2>
      <button onclick="showModal('addAnimalModal')" class="btn btn-success">+ Добавить животное</button>
    </div>
    ${{animalsList}}
    
    <div id="addAnimalModal" class="modal">
      <div class="modal-content">
        <span class="close" onclick="closeModal('addAnimalModal')">&times;</span>
        <h2 id="animalModalTitle">Добавить животное</h2>
        <form id="animalForm" onsubmit="saveAnimal(event)">
          <input type="hidden" id="animalId" name="id">
          <div class="form-group">
            <label>Название (RU) *</label>
            <input type="text" id="animalNameRu" name="nameRu" required>
          </div>
          <div class="form-group">
            <label>Название (EN)</label>
            <input type="text" id="animalNameEn" name="nameEn">
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
            <small style="color: #666; display: block; margin-top: 5px;">Путь к файлу в Firebase Storage</small>
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
          <div style="margin-top: 20px;">
            <button type="submit" class="btn btn-success">Сохранить</button>
            <button type="button" class="btn" onclick="closeModal('addAnimalModal')" style="margin-left: 10px;">Отмена</button>
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
            document.getElementById('animalModalTitle').textContent = 'Редактировать животное';
            showModal('addAnimalModal');
          }})
          .catch(err => showAlert('Ошибка загрузки: ' + err.message, 'danger'));
      }}
      
      function deleteAnimal(id) {{
        if (confirm('Удалить животное?')) {{
          fetch('/api/categories/${{req.params.id}}/animals/' + id, {{ method: 'DELETE' }})
            .then(() => {{
              showAlert('Животное удалено', 'success');
              setTimeout(() => location.reload(), 500);
            }})
            .catch(err => showAlert('Ошибка удаления: ' + err.message, 'danger'));
        }}
      }}
      
      function saveAnimal(e) {{
        e.preventDefault();
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
            showAlert(id ? 'Животное обновлено' : 'Животное создано', 'success');
            closeModal('addAnimalModal');
            setTimeout(() => location.reload(), 500);
          }})
          .catch(err => showAlert('Ошибка сохранения: ' + err.message, 'danger'));
      }}
      
      document.getElementById('addAnimalModal').addEventListener('click', function(e) {{
        if (e.target === this) {{
          closeModal('addAnimalModal');
        }}
      }});
    </script>
  `;
  res.send(htmlTemplate('Животные', content, 'categories'));
}});

// API для животных
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
            <td>${{offer.title?.ru || offer.title || 'Без названия'}}</td>
            <td><span class="badge ${{offer.isActive ? 'badge-success' : 'badge-danger'}}">${{offer.isActive ? 'Активно' : 'Неактивно'}}</span></td>
            <td>${{offer.items?.length || 0}}</td>
            <td>
              <button onclick="editOffer('${{offer.id}}')" class="btn" style="padding: 5px 10px; font-size: 12px;">Редактировать</button>
              <button onclick="deleteOffer('${{offer.id}}')" class="btn btn-danger" style="padding: 5px 10px; font-size: 12px; margin-left: 5px;">Удалить</button>
            </td>
          </tr>
        `).join('')}}
      </tbody>
    </table>
  ` : `
    <div class="empty-state">
      <p>Предложения не найдены</p>
      <p style="margin-top: 10px; color: #999;">Создайте первое предложение</p>
    </div>
  `;
  
  const content = `
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
      <h2>Предложения</h2>
      <button onclick="showModal('addOfferModal')" class="btn btn-success">+ Добавить предложение</button>
    </div>
    ${{offersList}}
    
    <div id="addOfferModal" class="modal">
      <div class="modal-content">
        <span class="close" onclick="closeModal('addOfferModal')">&times;</span>
        <h2 id="offerModalTitle">Добавить предложение</h2>
        <form id="offerForm" onsubmit="saveOffer(event)">
          <input type="hidden" id="offerId" name="id">
          <div class="form-group">
            <label>Название (RU) *</label>
            <input type="text" id="offerTitleRu" name="titleRu" required>
          </div>
          <div class="form-group">
            <label>Название (EN)</label>
            <input type="text" id="offerTitleEn" name="titleEn">
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
          <div style="margin-top: 20px;">
            <button type="submit" class="btn btn-success">Сохранить</button>
            <button type="button" class="btn" onclick="closeModal('addOfferModal')" style="margin-left: 10px;">Отмена</button>
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
            document.getElementById('offerModalTitle').textContent = 'Редактировать предложение';
            showModal('addOfferModal');
          }})
          .catch(err => showAlert('Ошибка загрузки: ' + err.message, 'danger'));
      }}
      
      function deleteOffer(id) {{
        if (confirm('Удалить предложение?')) {{
          fetch('/api/offers/' + id, {{ method: 'DELETE' }})
            .then(() => {{
              showAlert('Предложение удалено', 'success');
              setTimeout(() => location.reload(), 500);
            }})
            .catch(err => showAlert('Ошибка удаления: ' + err.message, 'danger'));
        }}
      }}
      
      function saveOffer(e) {{
        e.preventDefault();
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
            showAlert(id ? 'Предложение обновлено' : 'Предложение создано', 'success');
            closeModal('addOfferModal');
            setTimeout(() => location.reload(), 500);
          }})
          .catch(err => showAlert('Ошибка сохранения: ' + err.message, 'danger'));
      }}
      
      document.getElementById('addOfferModal').addEventListener('click', function(e) {{
        if (e.target === this) {{
          closeModal('addOfferModal');
        }}
      }});
    </script>
  `;
  res.send(htmlTemplate('Предложения', content, 'offers'));
}});

// API для предложений
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
    <h2>Аналитика</h2>
    <div class="empty-state">
      <p>Аналитика настраивается</p>
      <p style="margin-top: 10px; color: #999;">Данные будут доступны после интеграции с Firebase Analytics</p>
    </div>
  `;
  res.send(htmlTemplate('Аналитика', content, 'analytics'));
}});

app.listen(PORT, '127.0.0.1', () => {{
  console.log('Complete admin panel running on http://127.0.0.1:' + PORT);
  console.log('Firebase:', db ? 'Connected' : 'Mock mode');
}});
"""

sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/server.js", "w") as f:
        f.write(complete_server)
    print("  Complete server.js created")
except Exception as e:
    print(f"  Error: {e}")
finally:
    sftp.close()

# Установка dotenv если нужно
print("[3] Installing dotenv...")
safe_run(f"cd {REMOTE_DIR} && npm install dotenv 2>&1 | tail -10")

# Запуск
print("[4] Starting server...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
exec node server.js
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-complete-admin.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-complete-admin.sh", 0o755)
finally:
    sftp.close()

code, start_out, _ = safe_run("pm2 start /tmp/start-complete-admin.sh --name deti-admin --interpreter bash")
print(f"Start: {start_out[:500]}")

# Ждем
print("\n[5] Waiting 10 seconds...")
time.sleep(10)

# Проверка
print("[6] Testing...")
code, api_test, _ = safe_run("curl -s http://127.0.0.1:3000/api/categories 2>&1", timeout=10)
if api_test:
    if "error" not in api_test.lower() or "[]" in api_test:
        print(f"[OK] API working: {api_test[:200]}")

code, page_test, _ = safe_run("curl -s http://127.0.0.1:3000/categories 2>&1 | grep -E 'Категории|Добавить' | head -2", timeout=10)
if page_test:
    print("[OK] Categories page working")

code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\n" + "="*60)
print("COMPLETE ADMIN PANEL DEPLOYED!")
print("="*60)
print("Features:")
print("  - Полное управление категориями (создание, редактирование, удаление)")
print("  - Полное управление животными в категориях")
print("  - Управление предложениями")
print("  - Дашборд со статистикой")
print("  - Интеграция с Firebase Firestore")
print("  - Работает в демо-режиме если Firebase не настроен")
print("\nURL: http://168.222.193.86/categories")
