import { query } from '../db/index.js';

export const toggleLike = async (req, res) => {
    const { song_id } = req.body;
    const user_id = req.user.id;
    try {
        const check = await query('SELECT * FROM likes WHERE user_id = $1 AND song_id = $2', [user_id, song_id]);
        if (check.rows.length > 0) {
            await query('DELETE FROM likes WHERE user_id = $1 AND song_id = $2', [user_id, song_id]);
            res.json({ message: 'Song unliked', liked: false });
        } else {
            await query('INSERT INTO likes (user_id, song_id) VALUES ($1, $2)', [user_id, song_id]);
            res.json({ message: 'Song liked', liked: true });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error toggle like' });
    }
};

export const toggleFavorite = async (req, res) => {
    const { song_id } = req.body;
    const user_id = req.user.id;
    try {
        const check = await query('SELECT * FROM favorites WHERE user_id = $1 AND song_id = $2', [user_id, song_id]);
        if (check.rows.length > 0) {
            await query('DELETE FROM favorites WHERE user_id = $1 AND song_id = $2', [user_id, song_id]);
            res.json({ message: 'Removed from favorites', favorited: false });
        } else {
            await query('INSERT INTO favorites (user_id, song_id) VALUES ($1, $2)', [user_id, song_id]);
            res.json({ message: 'Added to favorites', favorited: true });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error toggle favorite' });
    }
};

export const toggleFollow = async (req, res) => {
    const { followed_id, followed_type } = req.body; // 'band' or 'user'
    const follower_id = req.user.id;
    try {
        const table = followed_type === 'band' ? 'band_follows' : 'user_follows';
        const id_col = followed_type === 'band' ? 'band_id' : 'followed_user_id';
        
        const check = await query(`SELECT * FROM ${table} WHERE follower_id = $1 AND ${id_col} = $2`, [follower_id, followed_id]);
        if (check.rows.length > 0) {
            await query(`DELETE FROM ${table} WHERE follower_id = $1 AND ${id_col} = $2`, [follower_id, followed_id]);
            res.json({ message: 'Unfollowed', following: false });
        } else {
            await query(`INSERT INTO ${table} (follower_id, ${id_col}) VALUES ($1, $2)`, [follower_id, followed_id]);
            res.json({ message: 'Followed', following: true });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error toggle follow' });
    }
};
