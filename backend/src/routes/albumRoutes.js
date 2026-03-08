import express from 'express';
import { createAlbum, getAlbums, getAlbumById } from '../controllers/albumController.js';
import { protect, artistOnly } from '../middleware/authMiddleware.js';
import { upload } from '../middleware/uploadMiddleware.js';

const router = express.Router();

router.route('/')
    .get(getAlbums)
    .post(protect, artistOnly, upload.fields([{ name: 'cover_image', maxCount: 1 }]), createAlbum);

router.get('/:id', getAlbumById);

export default router;
