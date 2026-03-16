import express from 'express';
import { getBandAnalytics, getSongStats } from '../controllers/analyticsController.js';
import { protect, artistOnly } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/:band_id', protect, artistOnly, getBandAnalytics);
router.get('/:band_id/song-stats', protect, artistOnly, getSongStats);

export default router;
