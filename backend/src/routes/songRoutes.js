import express from 'express';
import { uploadSong, getSongs, getSongById, deleteSong, playSong, updateSong, getMySongs } from '../controllers/songController.js';
import { protect, artistOnly } from '../middleware/authMiddleware.js';
import { upload } from '../middleware/uploadMiddleware.js';

const router = express.Router();

router.route('/')
    .get(getSongs)
    .post(protect, artistOnly, upload.fields([{ name: 'audio', maxCount: 1 }, { name: 'cover_image', maxCount: 1 }]), uploadSong);

router.get('/mine', protect, artistOnly, getMySongs);
router.get('/:id', getSongById);
router.get('/:id/play', playSong);
router.put('/:id', protect, artistOnly, upload.fields([{ name: 'cover_image', maxCount: 1 }]), updateSong);
router.delete('/:id', protect, artistOnly, deleteSong);

export default router;
