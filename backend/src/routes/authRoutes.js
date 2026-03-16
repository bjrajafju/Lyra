import express from 'express';
import { registerUser, loginUser, getUserProfile, getUserById, updateProfile, deleteAccount } from '../controllers/authController.js';
import { protect } from '../middleware/authMiddleware.js';
import { upload } from '../middleware/uploadMiddleware.js';

const router = express.Router();

router.post('/register', registerUser);
router.post('/login', loginUser);
router.get('/profile', protect, getUserProfile);
router.patch('/profile', protect, upload.fields([{ name: 'profile_picture', maxCount: 1 }]), updateProfile);
router.delete('/profile', protect, deleteAccount);
router.get('/user/:id', getUserById);

export default router;
