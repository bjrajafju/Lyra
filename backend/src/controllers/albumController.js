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
        res.status(500).json({ message: 'Server error creating album' });
    }
};

export const getAlbums = async (req, res) => {
    const { band_id } = req.query;
    try {
        let result;
        if (band_id) {
            result = await query('SELECT * FROM albums WHERE band_id = $1 ORDER BY release_date DESC', [band_id]);
        } else {
            result = await query('SELECT * FROM albums ORDER BY release_date DESC');
        }
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error fetching albums' });
    }
};

export const getAlbumById = async (req, res) => {
    try {
        const album = await query('SELECT * FROM albums WHERE id = $1', [req.params.id]);
        if (album.rows.length === 0) return res.status(404).json({ message: 'Album not found' });
        
        const songs = await query('SELECT * FROM songs WHERE album_id = $1 ORDER BY release_date ASC', [req.params.id]);
        
        const result = album.rows[0];
        result.songs = songs.rows;
        res.json(result);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error fetching album' });
    }
};
