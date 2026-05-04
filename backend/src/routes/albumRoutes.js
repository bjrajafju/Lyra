import express from 'express';
import { createAlbum, getAlbums, getAlbumById, updateAlbum, deleteAlbum, reorderAlbumSongs } from '../controllers/albumController.js';
import { protect, checkBandRole } from '../middleware/authMiddleware.js';
import { upload } from '../middleware/uploadMiddleware.js';

const router = express.Router();

router.route('/')
    .get(getAlbums)
    .post(protect, checkBandRole('editor'), upload.fields([{ name: 'cover_image', maxCount: 1 }]), createAlbum);

router.route('/:id')
    .get(getAlbumById)
    .put(protect, checkBandRole('editor'), upload.fields([{ name: 'cover_image', maxCount: 1 }]), updateAlbum)
    .delete(protect, checkBandRole('admin'), deleteAlbum);

router.patch('/:id/reorder', protect, checkBandRole('editor'), reorderAlbumSongs);

export default router;
