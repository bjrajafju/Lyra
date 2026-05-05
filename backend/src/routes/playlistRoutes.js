import express from "express";
import {
    createPlaylist,
    getPlaylists,
    getUserPlaylists,
    addSongToPlaylist,
    removeSongFromPlaylist,
    getPlaylistById,
    updatePlaylist,
    deletePlaylist,
    reorderPlaylistSongs,
    getPlaylistShareInfo,
} from "../controllers/playlistController.js";
import { protect } from "../middleware/authMiddleware.js";
import { upload } from "../middleware/uploadMiddleware.js";
import { verifyToken } from "../utils/jwt.js";

const router = express.Router();

// Optional auth middleware for public/private playlist access
const optionalAuth = (req, res, next) => {
    if (
        req.headers.authorization &&
        req.headers.authorization.startsWith("Bearer")
    ) {
        try {
            const token = req.headers.authorization.split(" ")[1];
            req.user = verifyToken(token);
        } catch (e) {}
    }
    next();
};

router.get("/mine", protect, getUserPlaylists);

router
    .route("/")
    .get(getPlaylists)
    .post(
        protect,
        upload.fields([{ name: "cover_image", maxCount: 1 }]),
        createPlaylist,
    );

router.post("/:id/songs", protect, addSongToPlaylist);
router.put("/:id/songs/reorder", protect, reorderPlaylistSongs);
router.get("/:id/share", getPlaylistShareInfo);

router
    .route("/:id")
    .get(optionalAuth, getPlaylistById)
    .put(
        protect,
        upload.fields([{ name: "cover_image", maxCount: 1 }]),
        updatePlaylist,
    )
    .delete(protect, deletePlaylist);

router.delete("/:id/songs/:songId", protect, removeSongFromPlaylist);

export default router;
