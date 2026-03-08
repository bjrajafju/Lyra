import { query } from '../db/index.js';

export const getBandAnalytics = async (req, res) => {
    const { band_id } = req.params;
    const user_id = req.user.id;
    try {
        // Check member
        const mem = await query('SELECT * FROM band_members WHERE band_id = $1 AND user_id = $2', [band_id, user_id]);
        if (mem.rows.length === 0) return res.status(403).json({ message: 'Not authorized for this band' });

        const bandInfo = await query('SELECT total_streams, created_at FROM bands WHERE id = $1', [band_id]);
        
        // Sum song stats directly
        const likes = await query('SELECT COUNT(*) FROM likes l JOIN songs s ON l.song_id = s.id WHERE s.band_id = $1', [band_id]);
        const followers = await query('SELECT COUNT(*) FROM band_follows WHERE band_id = $1', [band_id]);

        const topSongs = await query('SELECT id, title, play_count FROM songs WHERE band_id = $1 ORDER BY play_count DESC LIMIT 5', [band_id]);

        res.json({
            total_streams: bandInfo.rows[0].total_streams,
            total_likes: parseInt(likes.rows[0].count),
            total_followers: parseInt(followers.rows[0].count),
            top_songs: topSongs.rows
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Analytics error' });
    }
};
