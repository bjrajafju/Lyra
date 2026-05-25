import express from 'express';
import { createAlbum, getAlbums, getAlbumById, updateAlbum, deleteAlbum, reorderAlbumSongs } from '../controllers/albumController.js';
import { protect, checkBandRole, optionalProtect } from '../middleware/authMiddleware.js';
import { upload } from '../middleware/uploadMiddleware.js';

const router = express.Router();

router.route("/")
    .get(getAlbums)
    .post(protect, upload.fields([{ name: 'cover_image', maxCount: 1 }]), checkBandRole('editor'), createAlbum);

router.route('/:id')
    .get(optionalProtect, getAlbumById)
    .put(protect, upload.fields([{ name: 'cover_image', maxCount: 1 }]), checkBandRole('editor'), updateAlbum)
    .delete(protect, checkBandRole('admin'), deleteAlbum);

router.patch('/:id/reorder', protect, checkBandRole('editor'), reorderAlbumSongs);

export default router;
