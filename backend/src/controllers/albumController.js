import { query } from '../db/index.js';

export const createAlbum = async (req, res) => {
    const { band_id, title, description, release_date } = req.body;
    try {
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
        res.status(500).json({ message: 'Error creating album' });
    }
};

export const getAlbums = async (req, res) => {
    const { band_id } = req.query;
    try {
        let result;
        if (band_id) {
            result = await query(`
                SELECT a.*, 
                (SELECT COUNT(*) FROM album_songs WHERE album_id = a.id) as song_count
                FROM albums a WHERE a.band_id = $1 ORDER BY a.release_date DESC
            `, [band_id]);
        } else {
            result = await query(`
                SELECT a.*, b.name as band_name,
                (SELECT COUNT(*) FROM album_songs WHERE album_id = a.id) as song_count
                FROM albums a JOIN bands b ON a.band_id = b.id ORDER BY a.release_date DESC
            `);
        }
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error fetching albums' });
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
            SELECT s.*, b.name as band_name, als.position,
            (SELECT COUNT(*) FROM likes WHERE song_id = s.id) as like_count
            FROM songs s 
            JOIN album_songs als ON s.id = als.song_id
            JOIN bands b ON s.band_id = b.id 
            WHERE als.album_id = $1 AND s.status = 'published'
            ORDER BY als.position ASC
        `, [req.params.id]);
        
        const result = album.rows[0];
        result.songs = songs.rows;
        res.json(result);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error fetching album' });
    }
};

export const updateAlbum = async (req, res) => {
    const { title, description, release_date } = req.body;
    const albumId = req.params.id;
    try {
        let updateFields = ['updated_at = CURRENT_TIMESTAMP'];
        let values = [];
        let pIndex = 1;

        if (title) { updateFields.push(`title = $${pIndex++}`); values.push(title); }
        if (description !== undefined) { updateFields.push(`description = $${pIndex++}`); values.push(description); }
        if (release_date) { updateFields.push(`release_date = $${pIndex++}`); values.push(release_date); }
        if (req.files && req.files.cover_image) {
            updateFields.push(`cover_image = $${pIndex++}`);
            values.push(`/uploads/images/${req.files.cover_image[0].filename}`);
        }

        if (updateFields.length === 1) return res.status(400).json({ message: 'No fields to update' });

        values.push(albumId);
        const result = await query(
            `UPDATE albums SET ${updateFields.join(', ')} WHERE id = $${pIndex} RETURNING *`,
            values
        );
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error updating album' });
    }
};

export const deleteAlbum = async (req, res) => {
    const albumId = req.params.id;
    try {
        // album_songs links are cleaned by ON DELETE CASCADE
        await query('DELETE FROM albums WHERE id = $1', [albumId]);
        res.json({ message: 'Album deleted' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error deleting album' });
    }
};

export const reorderAlbumSongs = async (req, res) => {
    const { id } = req.params;
    const { songIds } = req.body;

    if (!songIds || !Array.isArray(songIds)) {
        return res.status(400).json({ message: 'songIds array is required' });
    }

    try {
        for (let i = 0; i < songIds.length; i++) {
            await query(
                'UPDATE album_songs SET position = $1 WHERE album_id = $2 AND song_id = $3',
                [i + 1, id, songIds[i]]
            );
        }
        res.json({ message: 'Songs reordered' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error reordering songs' });
    }
};
