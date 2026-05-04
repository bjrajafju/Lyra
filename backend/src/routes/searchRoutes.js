import express from 'express';
import { searchAll, getDiscovery, searchUsers } from '../controllers/searchController.js';
import { protect } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/', searchAll);
router.get('/discovery', getDiscovery);
router.get('/users', protect, searchUsers);

export default router;
