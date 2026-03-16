import { query } from '../db/index.js';

export const createAlbum = async (req, res) => {
    const { band_id, title, description, release_date } = req.body;
    try {
        // Check band membership
        const memberCheck = await query('SELECT * FROM band_members WHERE band_id = $1 AND user_id = $2', [band_id, req.user.id]);
        if (memberCheck.rows.length === 0) return res.status(403).json({ message: 'Not a member of this band' });

        let cover_image = null;
        if (req.files && req.files.cover_image) {
            cover_image = `/uploads/images/${req.files.cover_image[0].filename}`;
        }
        
        const result = await query(
            'INSERT INTO albums (band_id, title, description, cover_image, release_date) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [band_id, title, description, cover_image, release_date || null]
        );
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error creating album' });
    }
};

export const getAlbums = async (req, res) => {
    const { band_id } = req.query;
    try {
        let result;
        if (band_id) {
            result = await query(`
                SELECT a.*, 
                (SELECT COUNT(*) FROM songs WHERE album_id = a.id) as song_count
                FROM albums a WHERE a.band_id = $1 ORDER BY a.release_date DESC
            `, [band_id]);
        } else {
            result = await query(`
                SELECT a.*, b.name as band_name,
                (SELECT COUNT(*) FROM songs WHERE album_id = a.id) as song_count
                FROM albums a JOIN bands b ON a.band_id = b.id ORDER BY a.release_date DESC
            `);
        }
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error fetching albums' });
    }
};

export const getAlbumById = async (req, res) => {
    try {
        const album = await query(`
            SELECT a.*, b.name as band_name 
            FROM albums a JOIN bands b ON a.band_id = b.id 
            WHERE a.id = $1
        `, [req.params.id]);
        if (album.rows.length === 0) return res.status(404).json({ message: 'Album not found' });
        
        const songs = await query(`
            SELECT s.*, b.name as band_name,
            (SELECT COUNT(*) FROM likes WHERE song_id = s.id) as like_count
            FROM songs s JOIN bands b ON s.band_id = b.id 
            WHERE s.album_id = $1 ORDER BY s.release_date ASC
        `, [req.params.id]);
        
        const result = album.rows[0];
        result.songs = songs.rows;
        res.json(result);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error fetching album' });
    }
};

export const updateAlbum = async (req, res) => {
    const { title, description, release_date } = req.body;
    const albumId = req.params.id;
    try {
        const album = await query('SELECT * FROM albums WHERE id = $1', [albumId]);
        if (album.rows.length === 0) return res.status(404).json({ message: 'Album not found' });

        const memberCheck = await query('SELECT * FROM band_members WHERE band_id = $1 AND user_id = $2', [album.rows[0].band_id, req.user.id]);
        if (memberCheck.rows.length === 0) return res.status(403).json({ message: 'Not authorized' });

        let updateFields = [];
        let values = [];
        let paramIndex = 1;

        if (title) { updateFields.push(`title = $${paramIndex++}`); values.push(title); }
        if (description !== undefined) { updateFields.push(`description = $${paramIndex++}`); values.push(description); }
        if (release_date) { updateFields.push(`release_date = $${paramIndex++}`); values.push(release_date); }
        if (req.files && req.files.cover_image) {
            updateFields.push(`cover_image = $${paramIndex++}`);
            values.push(`/uploads/images/${req.files.cover_image[0].filename}`);
        }

        if (updateFields.length === 0) return res.status(400).json({ message: 'No fields to update' });

        values.push(albumId);
        const result = await query(
            `UPDATE albums SET ${updateFields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
            values
        );
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

export const deleteAlbum = async (req, res) => {
    const albumId = req.params.id;
    try {
        const album = await query('SELECT * FROM albums WHERE id = $1', [albumId]);
        if (album.rows.length === 0) return res.status(404).json({ message: 'Album not found' });

        const memberCheck = await query('SELECT * FROM band_members WHERE band_id = $1 AND user_id = $2', [album.rows[0].band_id, req.user.id]);
        if (memberCheck.rows.length === 0) return res.status(403).json({ message: 'Not authorized' });

        // Unlink songs from album (don't delete them)
        await query('UPDATE songs SET album_id = NULL WHERE album_id = $1', [albumId]);
        await query('DELETE FROM albums WHERE id = $1', [albumId]);
        res.json({ message: 'Album deleted' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};
