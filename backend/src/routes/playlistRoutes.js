import express from 'express';
import { createPlaylist, getPlaylists, addSongToPlaylist, getPlaylistById } from '../controllers/playlistController.js';
import { protect } from '../middleware/authMiddleware.js';
import { upload } from '../middleware/uploadMiddleware.js';

const router = express.Router();

router.route('/')
    .get(getPlaylists)
    .post(protect, upload.fields([{ name: 'cover_image', maxCount: 1 }]), createPlaylist);

router.post('/add-song', protect, addSongToPlaylist);

// Define a simple middleware to parse optional JWT for getPlaylistById without failing if unauthenticated
// Normally defined globally, but put directly in the route for brevity
const optionalAuth = (req, res, next) => {
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            import('../utils/jwt.js').then(({ verifyToken }) => {
                const token = req.headers.authorization.split(' ')[1];
                req.user = verifyToken(token);
                next();
            }).catch(() => next());
        } catch(e) { next(); }
    } else {
        next();
    }
};

router.get('/:id', optionalAuth, getPlaylistById);

export default router;
