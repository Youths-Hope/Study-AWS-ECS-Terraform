const express = require('express');
const mysql = require('mysql2');
const multer = require('multer');
const multerS3 = require('multer-s3');
const { S3Client, DeleteObjectCommand } = require('@aws-sdk/client-s3');

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// DB接続設定
const db = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// 接続確認
// DB作成
db.query(`CREATE DATABASE IF NOT EXISTS study_db`, (err) => {
  if (err) {
    console.error('DB作成失敗:', err);
    return;
  }
  console.log('DB確認OK');

  // DB切り替え
  db.query(`USE study_db`, (err) => {
    if (err) {
      console.error('DB選択失敗:', err);
      return;
    }

    // テーブル作成
    db.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100),
        email VARCHAR(255),
        image_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
  });
});

// API
#app.get('/', (req, res) => {
#  res.send('Hello World');
#});
app.get("/", (req, res) => {
  console.error("TEST ERROR: HTTP500");
  res.status(500).send("Internal Server Error");
});

// データ取得
app.get('/users', (req, res) => {
  db.query('SELECT * FROM users', (err, results) => {
    if (err) throw err;

    let html = '<h1>ユーザー一覧</h1>';

    results.forEach(user => {
      html += `
        <div style="margin-bottom:20px;">
          <p>ID: ${user.id}</p>
          <p>名前: ${user.name}</p>
          <p>メール: ${user.email}</p>
          ${user.image_url ? `<img src="${user.image_url}" width="200"><br>` : ''}
          <a href="/edit/${user.id}">編集</a>

          <form action="/delete/${user.id}" method="POST" style="display:inline;">
            <button type="submit">削除</button>
          </form>
          <hr>
        </div>
      `;
    });

    res.send(html);
  });
});

//フォーム表示
app.get('/form', (req, res) => {
  console.log("GET /form");

  res.sendFile(__dirname + '/form.html');
});

// S3設定
const s3 = new S3Client({
  region: 'ap-northeast-1'
});

// multer + S3設定
const upload = multer({
  storage: multerS3({
    s3: s3,
    bucket: process.env.S3_BUCKET_NAME,
    contentType: multerS3.AUTO_CONTENT_TYPE,
    key: function (req, file, cb) {
      cb(null, `images/${Date.now()}-${file.originalname}`);
    }
  })
});

//入力データの登録
app.post('/add', upload.single('image'), (req, res) => {
  const name = req.body.name;
  const email = req.body.email;
  const imageUrl = req.file ? req.file.location : null;

  console.log(`POST /add name=${name} email=${email}`);

  db.query(
    'INSERT INTO users (name, email, image_url) VALUES (?, ?, ?)',
    [name, email, imageUrl],

    (err) => {
      if (err) {
        console.error("DB Error:", err);
        return res.status(500).send("DB Error");
      }
      res.redirect('/users');
    }
  );
});

app.get('/edit/:id', (req, res) => {
  const id = req.params.id;

  db.query('SELECT * FROM users WHERE id = ?', [id], (err, results) => {
    if (err) throw err;

    if (results.length === 0) {
      return res.status(404).send('対象データが見つかりません');
    }

    const user = results[0];

    const html = `
      <form action="/update/${user.id}" method="POST">
        名前: <input type="text" name="name" value="${user.name}"><br>
        メール: <input type="text" name="email" value="${user.email}"><br>
        <button type="submit">更新</button>
      </form>
    `;

    res.send(html);
  });
});

app.post('/update/:id', (req, res) => {
  const id = req.params.id;
  const name = req.body.name;
  const email = req.body.email;

  console.log(`POST /edit name=${name} email=${email}`);

  db.query(
    'UPDATE users SET name = ?, email = ? WHERE id = ?',
    [name, email, id],
    (err) => {
      if (err) {
        console.error("UPDATE Error:", err);
        return res.status(500).send("Update Error");
      }

      res.redirect('/users');
    }
  );
});

app.post('/delete/:id', (req, res) => {
  const id = req.params.id;

  console.log(`DELETE user id=${id}`);

  // 先に対象レコード取得
  db.query('SELECT * FROM users WHERE id = ?', [id], async (err, results) => {
    if (err) {
      console.error("DELETE Error:", err);
      return res.status(500).send("Delete Error");
    }

    if (results.length === 0) {
      return res.status(404).send('対象データが見つかりません');
    }

    const user = results[0];
    const imageUrl = user.image_url;

    try {
      // image_url がある場合だけS3削除
      if (imageUrl) {
        const url = new URL(imageUrl);

        // /images/xxxx.png → images/xxxx.png
        const key = decodeURIComponent(url.pathname.substring(1));

        await s3.send(
          new DeleteObjectCommand({
            Bucket: process.env.S3_BUCKET_NAME,
            Key: key
          })
        );
      }

      // S3削除後にDB削除
      db.query('DELETE FROM users WHERE id = ?', [id], (err2) => {
        if (err2) {
          console.error("DELETE SQL Error:", err2);
          return res.status(500).send("Delete Error");
        }

        res.redirect('/users');
      });
    } catch (s3Err) {
      console.error('S3削除失敗:', s3Err);
      res.status(500).send('S3画像の削除に失敗しました');
    }
  });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server started on port ${PORT}`);
});