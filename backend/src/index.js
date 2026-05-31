import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import authRoutes from "./routes/authRoutes.js";
import bandRoutes from "./routes/bandRoutes.js";
import songRoutes from "./routes/songRoutes.js";
import interactionRoutes from "./routes/interactionRoutes.js";
import playlistRoutes from "./routes/playlistRoutes.js";
import commentRoutes from "./routes/commentRoutes.js";
import albumRoutes from "./routes/albumRoutes.js";
import searchRoutes from "./routes/searchRoutes.js";
import analyticsRoutes from "./routes/analyticsRoutes.js";
import invitationRoutes from "./routes/invitationRoutes.js";
import userRoutes from "./routes/userRoutes.js";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files for audio and images
app.use("/uploads", express.static("uploads"));

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/bands", bandRoutes);
app.use("/api/songs", songRoutes);
app.use("/api/interactions", interactionRoutes);
app.use("/api/playlists", playlistRoutes);
app.use("/api/comments", commentRoutes);
app.use("/api/albums", albumRoutes);
app.use("/api/search", searchRoutes);
app.use("/api/analytics", analyticsRoutes);
app.use("/api/invitations", invitationRoutes);
app.use("/api/users", userRoutes);

app.get("/health", (req, res) => {
    res.json({ status: "ok", message: "Lyra API is running" });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
