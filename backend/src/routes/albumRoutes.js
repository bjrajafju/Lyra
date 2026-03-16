import express from 'express';
import { createAlbum, getAlbums, getAlbumById, updateAlbum, deleteAlbum } from '../controllers/albumController.js';
import { protect, artistOnly } from '../middleware/authMiddleware.js';
import { upload } from '../middleware/uploadMiddleware.js';

const router = express.Router();

router.route('/')
    .get(getAlbums)
    .post(protect, artistOnly, upload.fields([{ name: 'cover_image', maxCount: 1 }]), createAlbum);

router.route('/:id')
    .get(getAlbumById)
    .put(protect, artistOnly, upload.fields([{ name: 'cover_image', maxCount: 1 }]), updateAlbum)
    .delete(protect, artistOnly, deleteAlbum);

export default router;
