import express from 'express';
import { searchAll, getDiscovery } from '../controllers/searchController.js';

const router = express.Router();

router.get('/', searchAll);
router.get('/discovery', getDiscovery);

export default router;
