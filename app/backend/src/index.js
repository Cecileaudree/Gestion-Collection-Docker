import express from 'express';
import mysql from 'mysql2/promise';
import dotenv from 'dotenv';
import cors from 'cors';

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json()); // Pour parser JSON

// Connexion MySQL
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT
});

// GET /items => liste tous les items
app.get('/items', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM items');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// POST /items => ajouter un item
app.post('/items', async (req, res) => {
  const { title, author, acquisition_date } = req.body;
  if (!title) return res.status(400).json({ error: 'Le titre est requis' });

  try {
    const [result] = await pool.query(
      'INSERT INTO items (title, author, acquisition_date) VALUES (?, ?, ? )',
      [title, author, acquisition_date]
    );
    res.status(201).json({ message: 'Item ajouté', itemId: result.insertId });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Test backend
app.get('/', (req, res) => res.send('Backend opérationnel !'));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Backend running on port ${PORT}`));
