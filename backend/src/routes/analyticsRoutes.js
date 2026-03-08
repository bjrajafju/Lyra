import express from 'express';
import { getBandAnalytics } from '../controllers/analyticsController.js';
import { protect, artistOnly } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/:band_id', protect, artistOnly, getBandAnalytics);

export default router;
