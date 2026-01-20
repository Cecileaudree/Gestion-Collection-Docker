const mysql = require("mysql2");

function connectWithRetry() {
  const db = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT,
  });

  db.connect((err) => {
    if (err) {
      console.log("❌ MySQL pas encore prêt, nouvelle tentative dans 5 secondes...");
      setTimeout(connectWithRetry, 5000);
    } else {
      console.log("✅ Connexion MySQL réussie");
    }
  });

  return db;
}

const db = connectWithRetry();
