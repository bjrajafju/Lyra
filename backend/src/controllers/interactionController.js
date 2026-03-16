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

export const getUserFavorites = async (req, res) => {
    const user_id = req.user.id;
    try {
        const result = await query(`
            SELECT s.*, b.name as band_name, f.created_at as favorited_at,
            (SELECT COUNT(*) FROM likes WHERE song_id = s.id) as like_count
            FROM favorites f
            JOIN songs s ON f.song_id = s.id
            JOIN bands b ON s.band_id = b.id
            WHERE f.user_id = $1
            ORDER BY f.created_at DESC
        `, [user_id]);
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error fetching favorites' });
    }
};

export const checkInteractionStatus = async (req, res) => {
    const { song_id, band_id, user_id: target_user_id } = req.query;
    const user_id = req.user.id;
    try {
        let liked = false, favorited = false, following_band = false, following_user = false;

        if (song_id) {
            const likeCheck = await query('SELECT 1 FROM likes WHERE user_id = $1 AND song_id = $2', [user_id, song_id]);
            liked = likeCheck.rows.length > 0;
            const favCheck = await query('SELECT 1 FROM favorites WHERE user_id = $1 AND song_id = $2', [user_id, song_id]);
            favorited = favCheck.rows.length > 0;
        }
        if (band_id) {
            const followCheck = await query('SELECT 1 FROM band_follows WHERE follower_id = $1 AND band_id = $2', [user_id, band_id]);
            following_band = followCheck.rows.length > 0;
        }
        if (target_user_id) {
            const followCheck = await query('SELECT 1 FROM user_follows WHERE follower_id = $1 AND followed_user_id = $2', [user_id, target_user_id]);
            following_user = followCheck.rows.length > 0;
        }

        res.json({ liked, favorited, following_band, following_user });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

export const getFollowingBands = async (req, res) => {
    const user_id = req.user.id;
    try {
        const result = await query(`
            SELECT b.*, bf.created_at as followed_at,
            (SELECT COUNT(*) FROM band_follows WHERE band_id = b.id) as follower_count
            FROM band_follows bf
            JOIN bands b ON bf.band_id = b.id
            WHERE bf.follower_id = $1
            ORDER BY bf.created_at DESC
        `, [user_id]);
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};
