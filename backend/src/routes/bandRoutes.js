import express from 'express';
import { createBand, getBands, getBandById } from '../controllers/bandController.js';
import { protect, artistOnly } from '../middleware/authMiddleware.js';
import { upload } from '../middleware/uploadMiddleware.js';

const router = express.Router();

router.route('/')
    .get(getBands)
    .post(protect, artistOnly, upload.fields([{ name: 'profile_image', maxCount: 1 }, { name: 'banner_image', maxCount: 1 }]), createBand);

router.route('/:id')
    .get(getBandById);

export default router;
