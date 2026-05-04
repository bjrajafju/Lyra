import express from 'express';
import { 
    getBandWidgets, 
    createWidget, 
    updateWidget, 
    deleteWidget, 
    reorderWidgets 
} from '../controllers/widgetController.js';
import { protect, checkBandRole } from '../middleware/authMiddleware.js';

const router = express.Router({ mergeParams: true });

// Publicly viewable
router.get('/', getBandWidgets);

// Protected (requires Editor role)
router.post('/', protect, checkBandRole('editor'), createWidget);
router.patch('/reorder', protect, checkBandRole('editor'), reorderWidgets);
router.patch('/:widgetId', protect, checkBandRole('editor'), updateWidget);
router.delete('/:widgetId', protect, checkBandRole('editor'), deleteWidget);

export default router;
