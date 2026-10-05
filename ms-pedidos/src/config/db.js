import pg from "pg";
const { Pool } = pg;

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === "production" ? { rejectUnauthorized: false } : false,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on("error", (err) => console.error("Error Postgres:", err));

export async function testConnection() {
  const { rows } = await pool.query("SELECT NOW() AS now");
  console.log(`✅ PostgreSQL conectado: ${rows[0].now}`);
}
