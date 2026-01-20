require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT
});

db.connect(err => {
  if (err) console.error("❌ MySQL error:", err);
  else console.log("✅ Connexion MySQL réussie");
});

// Routes
app.get('/', (req, res) => res.send('Backend Collection App'));

app.get('/items', (req, res) => {
  db.query('SELECT * FROM items', (err, results) => {
    if (err) return res.status(500).json(err);
    res.json(results);
  });
});

app.post('/items', (req, res) => {
  const { title, author, acquisition_date, condition } = req.body;
  db.query(
    'INSERT INTO items (title, author, acquisition_date, condition) VALUES (?, ?, ?, ?)',
    [title, author, acquisition_date, condition],
    (err, results) => {
      if (err) return res.status(500).json(err);
      res.json({ id: results.insertId, ...req.body });
    }
  );
});

app.listen(5000, () => console.log('🚀 Backend running on port 5000'));
