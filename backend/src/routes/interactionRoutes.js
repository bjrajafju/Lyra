import express from "express";
import {
    toggleLike,
    toggleFavorite,
    toggleFollow,
    getUserFavorites,
    checkInteractionStatus,
    getFollowingBands,
} from "../controllers/interactionController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/like", protect, toggleLike);
router.post("/favorite", protect, toggleFavorite);
router.post("/follow", protect, toggleFollow);
router.get("/favorites", protect, getUserFavorites);
router.get("/status", protect, checkInteractionStatus);
router.get("/following-bands", protect, getFollowingBands);

export default router;
