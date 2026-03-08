import express from "express";
import pool from "./services/db.js";

const app = express();
app.use(express.json());

app.get("/db-test", async (req, res) => {
    try {
        const result = await pool.query("SELECT NOW()");
        res.json({
            status: "ok",
            time: result.rows[0],
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "DB connection failed" });
    }
});

app.listen(3000, () => {
    console.log("Server running on port 3000");
});
