import express from 'express';
import { createBand, getBands, getBandById, updateBand, deleteBand, getUserBands } from '../controllers/bandController.js';
import { protect, artistOnly, checkBandRole } from '../middleware/authMiddleware.js';
import { upload } from '../middleware/uploadMiddleware.js';
import memberRoutes from './memberRoutes.js';
import widgetRoutes from './widgetRoutes.js';

const router = express.Router();

router.get('/my-bands', protect, getUserBands);

// Nest member management
router.use('/:bandId/members', memberRoutes);

// Nest widget management
router.use('/:bandId/widgets', widgetRoutes);

router.route('/')
    .get(getBands)
    .post(protect, artistOnly, upload.fields([{ name: 'profile_image', maxCount: 1 }, { name: 'banner_image', maxCount: 1 }]), createBand);

router.route('/:id')
    .get(getBandById)
    .put(protect, checkBandRole('editor'), upload.fields([{ name: 'profile_image', maxCount: 1 }, { name: 'banner_image', maxCount: 1 }]), updateBand)
    .delete(protect, checkBandRole('admin'), deleteBand);

export default router;
