import express from 'express';
import { createBand, getBands, getBandById, updateBand, deleteBand, getUserBands, addBandMember, removeBandMember } from '../controllers/bandController.js';
import { protect, artistOnly } from '../middleware/authMiddleware.js';
import { upload } from '../middleware/uploadMiddleware.js';

const router = express.Router();

router.get('/my-bands', protect, getUserBands);

router.route('/')
    .get(getBands)
    .post(protect, artistOnly, upload.fields([{ name: 'profile_image', maxCount: 1 }, { name: 'banner_image', maxCount: 1 }]), createBand);

router.route('/:id')
    .get(getBandById)
    .put(protect, artistOnly, upload.fields([{ name: 'profile_image', maxCount: 1 }, { name: 'banner_image', maxCount: 1 }]), updateBand)
    .delete(protect, artistOnly, deleteBand);

router.post('/:id/members', protect, artistOnly, addBandMember);
router.delete('/:id/members/:userId', protect, artistOnly, removeBandMember);

export default router;
