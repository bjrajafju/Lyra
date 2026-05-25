import express from "express";
import {
    uploadSong,
    getSongs,
    getSongById,
    deleteSong,
    playSong,
    updateSong,
    getMySongs,
    toggleSongStatus,
} from "../controllers/songController.js";
import { protect, checkBandRole } from "../middleware/authMiddleware.js";
import { upload } from "../middleware/uploadMiddleware.js";

const router = express.Router();

router
    .route("/")
    .get(getSongs)
    .post(
        protect,
        checkBandRole("editor"),
        upload.fields([
            { name: "audio", maxCount: 1 },
            { name: "cover_image", maxCount: 1 },
        ]),
        uploadSong,
    );

router.get("/mine", protect, checkBandRole("member"), getMySongs); // Internal dashboard
router.get("/", getSongs); // List all songs (with optional filtering)
router.get("/:id", getSongById);
router.get("/:id/play", playSong);
router.patch("/:id/status", protect, checkBandRole("editor"), toggleSongStatus);
router.put(
    "/:id",
    protect,
    checkBandRole("editor"),
    upload.fields([{ name: "cover_image", maxCount: 1 }]),
    updateSong,
);
router.delete("/:id", protect, checkBandRole("admin"), deleteSong);

export default router;
