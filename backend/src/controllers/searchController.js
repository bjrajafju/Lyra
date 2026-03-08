import { query } from '../db/index.js';

export const searchAll = async (req, res) => {
    const { q } = req.query;
    if (!q) return res.json({ songs: [], bands: [], playlists: [] });

    try {
        const searchStr = `%${q}%`;
        
        const songs = await query('SELECT s.*, b.name as band_name FROM songs s JOIN bands b ON s.band_id = b.id WHERE s.title ILIKE $1 AND s.visibility = $2 LIMIT 10', [searchStr, 'public']);
        const bands = await query('SELECT * FROM bands WHERE name ILIKE $1 LIMIT 10', [searchStr]);
        const playlists = await query('SELECT * FROM playlists WHERE title ILIKE $1 AND is_public = true LIMIT 10', [searchStr]);

        res.json({
            songs: songs.rows,
            bands: bands.rows,
            playlists: playlists.rows
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Search error' });
    }
};

export const getDiscovery = async (req, res) => {
    try {
        // Trending songs (simply mock via high play_count)
        const trending = await query('SELECT s.*, b.name as band_name FROM songs s JOIN bands b ON s.band_id = b.id WHERE s.visibility = $1 ORDER BY s.play_count DESC LIMIT 10', ['public']);
        // New releases
        const newReleases = await query('SELECT s.*, b.name as band_name FROM songs s JOIN bands b ON s.band_id = b.id WHERE s.visibility = $1 ORDER BY s.created_at DESC LIMIT 10', ['public']);
        
        res.json({
            trending: trending.rows,
            newReleases: newReleases.rows
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Discovery error' });
    }
};
