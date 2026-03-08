import { query } from '../db/index.js';

export const createPlaylist = async (req, res) => {
    const { title, description, is_public } = req.body;
    const creator_id = req.user.id;
    let cover_image = null;
    if (req.files && req.files.cover_image) {
        cover_image = `/uploads/images/${req.files.cover_image[0].filename}`;
    }

    try {
        const result = await query(
            'INSERT INTO playlists (creator_id, title, description, cover_image, is_public) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [creator_id, title, description, cover_image, is_public || false]
        );
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error creating playlist' });
    }
};

export const getPlaylists = async (req, res) => {
    try {
        const result = await query('SELECT p.*, u.username as creator_name FROM playlists p JOIN users u ON p.creator_id = u.id WHERE is_public = true ORDER BY created_at DESC LIMIT 20');
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error fetching playlists' });
    }
};

export const addSongToPlaylist = async (req, res) => {
    const { playlist_id, song_id } = req.body;
    const user_id = req.user.id;
    try {
        // Verify playlist ownership
        const playlist = await query('SELECT * FROM playlists WHERE id = $1 AND creator_id = $2', [playlist_id, user_id]);
        if (playlist.rows.length === 0) {
            return res.status(403).json({ message: 'Not authorized to modify this playlist' });
        }
        
        // Get max position
        const posResult = await query('SELECT COALESCE(MAX(position), 0) + 1 as next_pos FROM playlist_songs WHERE playlist_id = $1', [playlist_id]);
        const next_pos = posResult.rows[0].next_pos;

        // Add
        await query(
            'INSERT INTO playlist_songs (playlist_id, song_id, position) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING',
            [playlist_id, song_id, next_pos]
        );
        res.json({ message: 'Song added to playlist' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error modifying playlist' });
    }
};

export const getPlaylistById = async (req, res) => {
    try {
        const result = await query('SELECT p.*, u.username as creator_name FROM playlists p JOIN users u ON p.creator_id = u.id WHERE p.id = $1', [req.params.id]);
        if (result.rows.length === 0) return res.status(404).json({ message: 'Playlist not found' });
        
        const playlist = result.rows[0];
        if (!playlist.is_public && (!req.user || req.user.id !== playlist.creator_id)) {
            return res.status(403).json({ message: 'Private playlist' });
        }

        const songs = await query(`
            SELECT ps.position, s.*, b.name as band_name 
            FROM playlist_songs ps 
            JOIN songs s ON ps.song_id = s.id 
            JOIN bands b ON s.band_id = b.id
            WHERE ps.playlist_id = $1 
            ORDER BY ps.position ASC
        `, [playlist.id]);
        
        playlist.songs = songs.rows;
        res.json(playlist);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};
