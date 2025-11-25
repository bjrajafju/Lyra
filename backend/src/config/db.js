import pkg from "pg";
import dotenv from "dotenv";

dotenv.config();
const { Pool } = pkg;

const pool = new Pool({
    connectionString:
        process.env.DATABASE_URL ||
        "postgresql://postgres:322@localhost:5432/lyra",
});

export default pool;
