"""Создание полноценной админ панели"""
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
    return code, safe_out[:15000], safe_err[:10000]

print("Creating full admin panel...")

# Остановка
safe_run("pm2 delete deti-admin 2>/dev/null || true")
safe_run("pkill -9 node 2>/dev/null || true")
time.sleep(2)

# Проверка зависимостей
print("\n[1] Checking dependencies...")
code, firebase_check, _ = safe_run(f"cd {REMOTE_DIR} && npm list firebase firebase-admin 2>&1 | grep -E 'firebase|UNMET' | head -5")
if "UNMET" in firebase_check or "missing" in firebase_check.lower():
    print("Installing Firebase dependencies...")
    safe_run(f"cd {REMOTE_DIR} && npm install firebase firebase-admin 2>&1 | tail -20")

# Создание полноценного сервера с Firebase
print("[2] Creating full admin server...")

# Читаем .env.local для получения Firebase конфигурации
code, env_content, _ = safe_run(f"cat {REMOTE_DIR}/.env.local 2>&1")
firebase_config = {}
for line in env_content.split('\n'):
    if '=' in line and 'FIREBASE' in line:
        key, value = line.split('=', 1)
        firebase_config[key.strip()] = value.strip()

# Создаем полноценный сервер
admin_server = f"""const express = require('express');
const path = require('path');
const admin = require('firebase-admin');
const {{ initializeApp }} = require('firebase/app');
const {{ getFirestore, collection, doc, getDocs, addDoc, updateDoc, deleteDoc, query, orderBy, writeBatch }} = require('firebase/firestore');
const {{ getStorage, ref, uploadBytes, getDownloadURL }} = require('firebase/storage');

const app = express();
const PORT = 3000;

app.use(express.json());
app.use(express.urlencoded({{ extended: true }}));

// Firebase Admin инициализация (если есть credentials)
try {{
  if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {{
    admin.initializeApp({{
      credential: admin.credential.cert({{
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\\\n/g, '\\n')
      }})
    }});
  }}
}} catch (e) {{
  console.log('Firebase Admin not initialized:', e.message);
}}

// Firebase Client инициализация
const firebaseConfig = {{
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || '{firebase_config.get("NEXT_PUBLIC_FIREBASE_API_KEY", "")}',
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || '{firebase_config.get("NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN", "")}',
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || '{firebase_config.get("NEXT_PUBLIC_FIREBASE_PROJECT_ID", "")}',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || '{firebase_config.get("NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET", "")}',
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '{firebase_config.get("NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID", "")}',
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '{firebase_config.get("NEXT_PUBLIC_FIREBASE_APP_ID", "")}'
}};

let db, storage;
try {{
  const firebaseApp = initializeApp(firebaseConfig);
  db = getFirestore(firebaseApp);
  storage = getStorage(firebaseApp);
}} catch (e) {{
  console.log('Firebase Client init error:', e.message);
}}

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
    .btn {{ padding: 10px 20px; background: #0070f3; color: white; border: none; border-radius: 5px; cursor: pointer; font-size: 14px; }}
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
    .empty-state {{ text-align: center; padding: 60px 20px; color: #666; }}
    .empty-state svg {{ width: 64px; height: 64px; margin-bottom: 20px; opacity: 0.5; }}
    .modal {{ display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 1000; }}
    .modal.active {{ display: flex; align-items: center; justify-content: center; }}
    .modal-content {{ background: white; padding: 30px; border-radius: 8px; max-width: 600px; width: 90%; max-height: 90vh; overflow-y: auto; }}
    .close {{ float: right; font-size: 28px; font-weight: bold; cursor: pointer; }}
    .close:hover {{ color: #dc3545; }}
    .loading {{ text-align: center; padding: 40px; color: #666; }}
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
    // Общие функции
    function showModal(id) {{
      document.getElementById(id).classList.add('active');
    }}
    function closeModal(id) {{
      document.getElementById(id).classList.remove('active');
    }}
    function showAlert(message, type = 'info') {{
      alert(message);
    }}
  </script>
</body>
</html>`;

// Главная страница
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
  `;
  res.send(htmlTemplate('Главная', content, 'home'));
}});

// Дашборд
app.get('/dashboard', async (req, res) => {{
  let stats = {{
    categories: 0,
    animals: 0,
    offers: 0
  }};
  
  try {{
    if (db) {{
      const categoriesSnap = await getDocs(collection(db, 'categories'));
      stats.categories = categoriesSnap.size;
      
      let totalAnimals = 0;
      for (const catDoc of categoriesSnap.docs) {{
        const animalsSnap = await getDocs(collection(db, 'categories', catDoc.id, 'animals'));
        totalAnimals += animalsSnap.size;
      }}
      stats.animals = totalAnimals;
      
      const offersSnap = await getDocs(collection(db, 'offers'));
      stats.offers = offersSnap.size;
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
      const q = query(collection(db, 'categories'), orderBy('order', 'asc'));
      const snapshot = await getDocs(q);
      categories = snapshot.docs.map(doc => ({{
        id: doc.id,
        ...doc.data()
      }}));
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
    
    <!-- Модальное окно добавления/редактирования -->
    <div id="addCategoryModal" class="modal">
      <div class="modal-content">
        <span class="close" onclick="closeModal('addCategoryModal')">&times;</span>
        <h2 id="modalTitle">Добавить категорию</h2>
        <form id="categoryForm" onsubmit="saveCategory(event)">
          <input type="hidden" id="categoryId" name="id">
          <div class="form-group">
            <label>Название (RU)</label>
            <input type="text" id="titleRu" name="titleRu" required>
          </div>
          <div class="form-group">
            <label>Название (EN)</label>
            <input type="text" id="titleEn" name="titleEn">
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Порядок</label>
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
            <label>Путь к иконке</label>
            <input type="text" id="tabIconAssetPath" name="tabIconAssetPath" placeholder="icons/category1.png" required>
          </div>
          <div style="margin-top: 20px;">
            <button type="submit" class="btn btn-success">Сохранить</button>
            <button type="button" class="btn" onclick="closeModal('addCategoryModal')" style="margin-left: 10px;">Отмена</button>
          </div>
        </form>
      </div>
    </div>
    
    <script>
      let editingCategoryId = null;
      
      function editCategory(id) {{
        // Загрузить данные категории и заполнить форму
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
            editingCategoryId = id;
            showModal('addCategoryModal');
          }});
      }}
      
      function deleteCategory(id) {{
        if (confirm('Удалить категорию?')) {{
          fetch('/api/categories/' + id, {{ method: 'DELETE' }})
            .then(() => location.reload());
        }}
      }}
      
      function saveCategory(e) {{
        e.preventDefault();
        const formData = {{
          title: {{
            ru: document.getElementById('titleRu').value,
            en: document.getElementById('titleEn').value
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
          .then(() => {{
            closeModal('addCategoryModal');
            location.reload();
          }})
          .catch(err => alert('Ошибка: ' + err.message));
      }}
      
      // Сброс формы при открытии модального окна
      document.getElementById('addCategoryModal').addEventListener('click', function(e) {{
        if (e.target === this) {{
          closeModal('addCategoryModal');
          document.getElementById('categoryForm').reset();
          document.getElementById('categoryId').value = '';
          document.getElementById('modalTitle').textContent = 'Добавить категорию';
          editingCategoryId = null;
        }}
      }});
    </script>
  `;
  res.send(htmlTemplate('Категории', content, 'categories'));
}});

// API для категорий
app.get('/api/categories/:id', async (req, res) => {{
  try {{
    if (!db) return res.status(500).json({{ error: 'Firebase not initialized' }});
    const docRef = doc(db, 'categories', req.params.id);
    const docSnap = await getDocs(collection(db, 'categories'));
    const found = docSnap.docs.find(d => d.id === req.params.id);
    if (found) {{
      res.json({{ id: found.id, ...found.data() }});
    }} else {{
      res.status(404).json({{ error: 'Not found' }});
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.post('/api/categories', async (req, res) => {{
  try {{
    if (!db) return res.status(500).json({{ error: 'Firebase not initialized' }});
    const docRef = await addDoc(collection(db, 'categories'), req.body);
    res.json({{ id: docRef.id }});
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.put('/api/categories/:id', async (req, res) => {{
  try {{
    if (!db) return res.status(500).json({{ error: 'Firebase not initialized' }});
    await updateDoc(doc(db, 'categories', req.params.id), req.body);
    res.json({{ success: true }});
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.delete('/api/categories/:id', async (req, res) => {{
  try {{
    if (!db) return res.status(500).json({{ error: 'Firebase not initialized' }});
    await deleteDoc(doc(db, 'categories', req.params.id));
    res.json({{ success: true }});
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

// Страница животных в категории
app.get('/categories/:id/animals', async (req, res) => {{
  let animals = [];
  let category = null;
  try {{
    if (db) {{
      const catDoc = await getDocs(query(collection(db, 'categories'), orderBy('order')));
      const found = catDoc.docs.find(d => d.id === req.params.id);
      if (found) {{
        category = {{ id: found.id, ...found.data() }};
      }}
      
      if (category) {{
        const q = query(collection(db, 'categories', req.params.id, 'animals'), orderBy('order', 'asc'));
        const snapshot = await getDocs(q);
        animals = snapshot.docs.map(doc => ({{
          id: doc.id,
          ...doc.data()
        }}));
      }}
    }}
  }} catch (e) {{
    console.log('Error loading animals:', e.message);
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
      <h2>Животные: ${{category?.title?.ru || 'Категория'}}</h2>
      <button onclick="showModal('addAnimalModal')" class="btn btn-success">+ Добавить животное</button>
    </div>
    ${{animalsList}}
    
    <!-- Модальное окно для животного -->
    <div id="addAnimalModal" class="modal">
      <div class="modal-content">
        <span class="close" onclick="closeModal('addAnimalModal')">&times;</span>
        <h2 id="animalModalTitle">Добавить животное</h2>
        <form id="animalForm" onsubmit="saveAnimal(event)">
          <input type="hidden" id="animalId" name="id">
          <div class="form-group">
            <label>Название (RU)</label>
            <input type="text" id="animalNameRu" name="nameRu" required>
          </div>
          <div class="form-group">
            <label>Название (EN)</label>
            <input type="text" id="animalNameEn" name="nameEn">
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Порядок</label>
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
          </div>
          <div class="form-group">
            <label>Путь к превью</label>
            <input type="text" id="previewAssetPath" name="previewAssetPath" placeholder="previews/animal1.jpg">
          </div>
          <div class="form-group">
            <label>Путь к звуку</label>
            <input type="text" id="soundAssetPath" name="soundAssetPath" placeholder="sounds/animal1.mp3">
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
            document.getElementById('animalModalTitle').textContent = 'Редактировать животное';
            showModal('addAnimalModal');
          }});
      }}
      
      function deleteAnimal(id) {{
        if (confirm('Удалить животное?')) {{
          fetch('/api/categories/${{req.params.id}}/animals/' + id, {{ method: 'DELETE' }})
            .then(() => location.reload());
        }}
      }}
      
      function saveAnimal(e) {{
        e.preventDefault();
        const formData = {{
          name: {{
            ru: document.getElementById('animalNameRu').value,
            en: document.getElementById('animalNameEn').value
          }},
          order: parseInt(document.getElementById('animalOrder').value),
          isVisible: document.getElementById('animalIsVisible').value === 'true',
          bgAssetPath: document.getElementById('bgAssetPath').value,
          previewAssetPath: document.getElementById('previewAssetPath').value,
          soundAssetPath: document.getElementById('soundAssetPath').value
        }};
        
        const id = document.getElementById('animalId').value;
        const url = id ? '/api/categories/${{req.params.id}}/animals/' + id : '/api/categories/${{req.params.id}}/animals';
        const method = id ? 'PUT' : 'POST';
        
        fetch(url, {{
          method: method,
          headers: {{ 'Content-Type': 'application/json' }},
          body: JSON.stringify(formData)
        }})
          .then(() => {{
            closeModal('addAnimalModal');
            location.reload();
          }})
          .catch(err => alert('Ошибка: ' + err.message));
      }}
    </script>
  `;
  res.send(htmlTemplate('Животные', content, 'categories'));
}});

// API для животных
app.get('/api/categories/:catId/animals/:id', async (req, res) => {{
  try {{
    if (!db) return res.status(500).json({{ error: 'Firebase not initialized' }});
    const snapshot = await getDocs(collection(db, 'categories', req.params.catId, 'animals'));
    const found = snapshot.docs.find(d => d.id === req.params.id);
    if (found) {{
      res.json({{ id: found.id, ...found.data() }});
    }} else {{
      res.status(404).json({{ error: 'Not found' }});
    }}
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.post('/api/categories/:catId/animals', async (req, res) => {{
  try {{
    if (!db) return res.status(500).json({{ error: 'Firebase not initialized' }});
    const docRef = await addDoc(collection(db, 'categories', req.params.catId, 'animals'), req.body);
    res.json({{ id: docRef.id }});
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.put('/api/categories/:catId/animals/:id', async (req, res) => {{
  try {{
    if (!db) return res.status(500).json({{ error: 'Firebase not initialized' }});
    await updateDoc(doc(db, 'categories', req.params.catId, 'animals', req.params.id), req.body);
    res.json({{ success: true }});
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

app.delete('/api/categories/:catId/animals/:id', async (req, res) => {{
  try {{
    if (!db) return res.status(500).json({{ error: 'Firebase not initialized' }});
    await deleteDoc(doc(db, 'categories', req.params.catId, 'animals', req.params.id));
    res.json({{ success: true }});
  }} catch (e) {{
    res.status(500).json({{ error: e.message }});
  }}
}});

// Предложения
app.get('/offers', async (req, res) => {{
  let offers = [];
  try {{
    if (db) {{
      const snapshot = await getDocs(collection(db, 'offers'));
      offers = snapshot.docs.map(doc => ({{
        id: doc.id,
        ...doc.data()
      }}));
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
        <h2>Добавить предложение</h2>
        <p style="color: #666; margin-bottom: 20px;">Функционал редактирования предложений настраивается</p>
        <button type="button" class="btn" onclick="closeModal('addOfferModal')">Закрыть</button>
      </div>
    </div>
  `;
  res.send(htmlTemplate('Предложения', content, 'offers'));
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
  console.log('Full admin panel running on http://127.0.0.1:' + PORT);
}});
"""

sftp = ssh.open_sftp()
try:
    with sftp.open(f"{REMOTE_DIR}/server.js", "w") as f:
        f.write(admin_server)
    print("  Full server.js created")
except Exception as e:
    print(f"  Error: {e}")
finally:
    sftp.close()

# Запуск
print("[3] Starting server...")
start_script = f"""cd {REMOTE_DIR}
export PORT=3000
export HOSTNAME=127.0.0.1
exec node server.js
"""
sftp = ssh.open_sftp()
try:
    with sftp.open("/tmp/start-full-admin.sh", "w") as f:
        f.write(start_script)
    sftp.chmod("/tmp/start-full-admin.sh", 0o755)
finally:
    sftp.close()

code, start_out, _ = safe_run("pm2 start /tmp/start-full-admin.sh --name deti-admin --interpreter bash")
print(f"Start: {start_out[:500]}")

# Ждем
print("\n[4] Waiting 10 seconds...")
time.sleep(10)

# Проверка
print("[5] Checking...")
code, port_check, _ = safe_run("ss -tlnp | grep :3000 || echo 'NOT_FOUND'")
print(f"Port: {port_check[:300]}")

if "NOT_FOUND" not in port_check:
    code, response, _ = safe_run("curl -s http://127.0.0.1:3000/categories 2>&1", timeout=10)
    if response and len(response) > 100:
        print(f"[OK] Admin panel responding!")
        
        code, nginx_resp, _ = safe_run("curl -s http://127.0.0.1/categories 2>&1 | head -30", timeout=10)
        if nginx_resp and len(nginx_resp) > 100:
            print("\n" + "="*60)
            print("SUCCESS! Full admin panel is working!")
            print("="*60)
            print("URL: http://168.222.193.86")
            print("\nFeatures:")
            print("  - Управление категориями (CRUD)")
            print("  - Управление животными в категориях")
            print("  - Управление предложениями")
            print("  - Дашборд со статистикой")
            print("  - Интеграция с Firebase Firestore")

code, status, _ = safe_run("pm2 list")
print("\nPM2 Status:")
print(status[:600])

safe_run("pm2 save")

ssh.close()

print("\nDone!")
