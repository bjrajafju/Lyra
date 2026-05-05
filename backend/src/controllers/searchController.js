import { query } from "../db/index.js";

export const searchAll = async (req, res) => {
    const { q } = req.query;
    if (!q) return res.json({ songs: [], bands: [], playlists: [] });

    try {
        const searchStr = `%${q}%`;

        const songs = await query(
            "SELECT s.*, b.name as band_name FROM songs s JOIN bands b ON s.band_id = b.id WHERE s.title ILIKE $1 AND s.status = $2 LIMIT 10",
            [searchStr, "published"],
        );
        const bands = await query(
            "SELECT * FROM bands WHERE name ILIKE $1 LIMIT 10",
            [searchStr],
        );
        const playlists = await query(
            "SELECT * FROM playlists WHERE title ILIKE $1 AND is_public = true LIMIT 10",
            [searchStr],
        );

        res.json({
            songs: songs.rows,
            bands: bands.rows,
            playlists: playlists.rows,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Search error" });
    }
};

export const searchUsers = async (req, res) => {
    const { q, page = 1, limit = 10, excludeBandId } = req.query;
    if (!q) return res.json({ users: [], total: 0 });

    const offset = (page - 1) * limit;
    const searchStr = `%${q}%`;

    try {
        let sql =
            "SELECT id, username, profile_picture FROM users WHERE username ILIKE $1";
        let params = [searchStr];

        if (excludeBandId) {
            sql +=
                " AND id NOT IN (SELECT user_id FROM band_members WHERE band_id = $2)";
            params.push(excludeBandId);
        }

        const countResult = await query(
            `SELECT COUNT(*) FROM (${sql}) as sub`,
            params,
        );
        const total = parseInt(countResult.rows[0].count);

        const usersSql =
            sql + ` LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
        const usersParams = [...params, limit, offset];

        const users = await query(usersSql, usersParams);

        res.json({
            users: users.rows,
            total,
            page: parseInt(page),
            limit: parseInt(limit),
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "User search error" });
    }
};

export const getDiscovery = async (req, res) => {
    try {
        // Trending songs (simply mock via high play_count)
        const trending = await query(
            "SELECT s.*, b.name as band_name FROM songs s JOIN bands b ON s.band_id = b.id WHERE s.status = $1 ORDER BY s.play_count DESC LIMIT 10",
            ["published"],
        );
        // New releases
        const newReleases = await query(
            "SELECT s.*, b.name as band_name FROM songs s JOIN bands b ON s.band_id = b.id WHERE s.status = $1 ORDER BY s.created_at DESC LIMIT 10",
            ["published"],
        );

        res.json({
            trending: trending.rows,
            newReleases: newReleases.rows,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Discovery error" });
    }
};

export const getGenres = async (req, res) => {
    try {
        const result = await query("SELECT * FROM genres ORDER BY name ASC");
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Error fetching genres" });
    }
};
