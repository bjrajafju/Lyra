import express from 'express';
import { toggleLike, toggleFavorite, toggleFollow } from '../controllers/interactionController.js';
import { protect } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/like', protect, toggleLike);
router.post('/favorite', protect, toggleFavorite);
router.post('/follow', protect, toggleFollow);

export default router;
