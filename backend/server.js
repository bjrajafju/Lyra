import express from "express";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Rota de teste
app.get("/", (req, res) => {
    res.send("Servidor Lyra está a funcionar 🎵");
});

// Iniciar servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Servidor a correr na porta ${PORT}`);
});
