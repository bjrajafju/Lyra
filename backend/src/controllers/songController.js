import { query } from '../db/index.js';
import { verifyToken } from '../utils/jwt.js';

export const uploadSong = async (req, res) => {
    try {
        const { band_id, album_id, title, description, duration, release_date, genre, visibility, tags } = req.body;
        const uploaded_by = req.user.id;

        let actual_band_id = band_id;

        if (band_id) {
            const bandCheck = await query('SELECT * FROM bands WHERE id = $1', [band_id]);
            if (bandCheck.rows.length === 0) {
                const newBand = await query('INSERT INTO bands (name, creator_id) VALUES ($1, $2) RETURNING id', ['My Band', uploaded_by]);
                actual_band_id = newBand.rows[0].id;
                await query('INSERT INTO band_members (band_id, user_id, role_in_band) VALUES ($1, $2, $3)', [actual_band_id, uploaded_by, 'admin']);
            } else {
                const memberCheck = await query('SELECT * FROM band_members WHERE band_id = $1 AND user_id = $2', [band_id, uploaded_by]);
                if (memberCheck.rows.length === 0) {
                    await query('INSERT INTO band_members (band_id, user_id, role_in_band) VALUES ($1, $2, $3)', [band_id, uploaded_by, 'member']);
                }
            }
        }

        if (!req.files || !req.files.audio) {
            return res.status(400).json({ message: 'Audio file is required' });
        }

        const audio_url = `/uploads/audio/${req.files.audio[0].filename}`;
        let cover_image = null;
        if (req.files.cover_image) {
            cover_image = `/uploads/images/${req.files.cover_image[0].filename}`;
        }

        const newSong = await query(
            `INSERT INTO songs 
            (band_id, album_id, uploaded_by, title, description, audio_url, cover_image, duration, release_date, genre, visibility, tags) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING *`,
            [actual_band_id, album_id || null, uploaded_by, title, description, audio_url, cover_image, duration, release_date || null, genre, visibility || 'public', JSON.stringify(tags || [])]
        );

        res.status(201).json(newSong.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error uploading song' });
    }
};

export const getSongs = async (req, res) => {
    const { page = 1, limit = 20, band_id } = req.query;
    const offset = (page - 1) * limit;

    try {
        let result;
        if (band_id) {
            result = await query(`
                SELECT s.*, b.name as band_name,
                (SELECT COUNT(*) FROM likes WHERE song_id = s.id) as like_count
                FROM songs s JOIN bands b ON s.band_id = b.id 
                WHERE s.band_id = $1 AND visibility = $2 
                ORDER BY s.created_at DESC LIMIT $3 OFFSET $4`, 
                [band_id, 'public', limit, offset]);
        } else {
            result = await query(`
                SELECT s.*, b.name as band_name,
                (SELECT COUNT(*) FROM likes WHERE song_id = s.id) as like_count
                FROM songs s JOIN bands b ON s.band_id = b.id 
                WHERE visibility = $1 
                ORDER BY s.created_at DESC LIMIT $2 OFFSET $3`, 
                ['public', limit, offset]);
        }
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error fetching songs' });
    }
};

export const getSongById = async (req, res) => {
    const { id } = req.params;
    try {
        const result = await query(`
            SELECT s.*, b.name as band_name,
            (SELECT COUNT(*) FROM likes WHERE song_id = s.id) as like_count,
            (SELECT COUNT(*) FROM favorites WHERE song_id = s.id) as favorite_count
            FROM songs s JOIN bands b ON s.band_id = b.id WHERE s.id = $1
        `, [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Song not found' });
        }
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

export const deleteSong = async (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;
    try {
        const song = await query('SELECT * FROM songs WHERE id = $1', [id]);
        if (song.rows.length === 0) return res.status(404).json({ message: 'Song not found' });

        // Check if user is band member
        const memberCheck = await query(
            'SELECT * FROM band_members WHERE band_id = $1 AND user_id = $2',
            [song.rows[0].band_id, userId]
        );
        if (memberCheck.rows.length === 0) {
            return res.status(403).json({ message: 'Not authorized to delete this song' });
        }

        await query('DELETE FROM songs WHERE id = $1', [id]);
        res.json({ message: 'Song deleted successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error deleting song' });
    }
};

export const playSong = async (req, res) => {
    const { id } = req.params;
    try {
        await query('UPDATE songs SET play_count = play_count + 1 WHERE id = $1', [id]);
        
        let user_id = null;
        if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
            try {
                const token = req.headers.authorization.split(' ')[1];
                const decoded = verifyToken(token);
                user_id = decoded.id;
            } catch (err) {}
        }
        
        await query('INSERT INTO streams (song_id, user_id) VALUES ($1, $2)', [id, user_id]);
        
        if (user_id) {
            await query('INSERT INTO listening_history (user_id, song_id) VALUES ($1, $2)', [user_id, id]);
        }

        // Update band total_streams
        await query(`
            UPDATE bands SET total_streams = total_streams + 1 
            WHERE id = (SELECT band_id FROM songs WHERE id = $1)
        `, [id]);

        const result = await query('SELECT s.*, b.name as band_name FROM songs s JOIN bands b ON s.band_id = b.id WHERE s.id = $1', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Song not found' });
        }
        
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error playing song' });
    }
};
