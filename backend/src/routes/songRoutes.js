import express from 'express';
import { uploadSong, getSongs, playSong } from '../controllers/songController.js';
import { protect, artistOnly } from '../middleware/authMiddleware.js';
import { upload } from '../middleware/uploadMiddleware.js';

const router = express.Router();

router.route('/')
    .get(getSongs)
    .post(protect, artistOnly, upload.fields([{ name: 'audio', maxCount: 1 }, { name: 'cover_image', maxCount: 1 }]), uploadSong);

router.get('/:id/play', playSong);

export default router;
