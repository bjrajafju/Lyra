import { query } from "../db/index.js";

const normalizePagination = (
    page,
    limit,
    defaultLimit = 20,
    maxLimit = 100,
) => {
    const parsedPage = Number.parseInt(page, 10);
    const parsedLimit = Number.parseInt(limit, 10);
    const safePage =
        Number.isNaN(parsedPage) || parsedPage < 1 ? 1 : parsedPage;
    const safeLimitRaw =
        Number.isNaN(parsedLimit) || parsedLimit < 1
            ? defaultLimit
            : parsedLimit;
    const safeLimit = Math.min(safeLimitRaw, maxLimit);
    const offset = (safePage - 1) * safeLimit;
    return { page: safePage, limit: safeLimit, offset };
};

export const createPlaylist = async (req, res) => {
    const { title, description, is_public } = req.body;
    const creator_id = req.user.id;
    let cover_image = null;
    if (req.files && req.files.cover_image) {
        cover_image = `/uploads/images/${req.files.cover_image[0].filename}`;
    }

    try {
        const result = await query(
            "INSERT INTO playlists (creator_id, title, description, cover_image, is_public) VALUES ($1, $2, $3, $4, $5) RETURNING *",
            [creator_id, title, description, cover_image, is_public || false],
        );
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error creating playlist" });
    }
};

export const getPlaylists = async (req, res) => {
    const { page = 1, limit = 20, sort = "recent" } = req.query;
    const { limit: safeLimit, offset } = normalizePagination(page, limit);
    const orderClause =
        sort === "popular"
            ? "song_count DESC, p.created_at DESC"
            : "p.created_at DESC";

    try {
        const result = await query(
            `
            SELECT p.*, u.username as creator_name,
            (SELECT COUNT(*) FROM playlist_songs WHERE playlist_id = p.id) as song_count
            FROM playlists p JOIN users u ON p.creator_id = u.id 
            WHERE is_public = true
            ORDER BY ${orderClause}
            LIMIT $1 OFFSET $2
        `,
            [safeLimit, offset],
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error fetching playlists" });
    }
};

export const getUserPlaylists = async (req, res) => {
    const userId = req.user.id;
    try {
        const result = await query(
            `
            SELECT p.*, u.username as creator_name,
            (SELECT COUNT(*) FROM playlist_songs WHERE playlist_id = p.id) as song_count
            FROM playlists p JOIN users u ON p.creator_id = u.id 
            WHERE p.creator_id = $1 ORDER BY p.created_at DESC
        `,
            [userId],
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error" });
    }
};

export const addSongToPlaylist = async (req, res) => {
    const playlist_id = Number.parseInt(req.params.id, 10);
    const song_id = Number.parseInt(req.body.song_id, 10);
    const user_id = req.user.id;
    if (Number.isNaN(playlist_id) || Number.isNaN(song_id)) {
        return res
            .status(400)
            .json({ message: "playlist_id and song_id are required" });
    }

    try {
        const playlist = await query(
            "SELECT * FROM playlists WHERE id = $1 AND creator_id = $2",
            [playlist_id, user_id],
        );
        if (playlist.rows.length === 0) {
            return res
                .status(403)
                .json({ message: "Not authorized to modify this playlist" });
        }

        const songCheck = await query(
            "SELECT id FROM songs WHERE id = $1 AND visibility = $2",
            [song_id, "public"],
        );
        if (songCheck.rows.length === 0) {
            return res
                .status(404)
                .json({ message: "Song not found or not public" });
        }

        const posResult = await query(
            "SELECT COALESCE(MAX(position), 0) + 1 as next_pos FROM playlist_songs WHERE playlist_id = $1",
            [playlist_id],
        );
        const next_pos = posResult.rows[0].next_pos;

        const insertResult = await query(
            "INSERT INTO playlist_songs (playlist_id, song_id, position) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING RETURNING playlist_id",
            [playlist_id, song_id, next_pos],
        );
        if (insertResult.rows.length === 0) {
            return res
                .status(409)
                .json({ message: "Song already exists in playlist" });
        }

        res.status(201).json({ message: "Song added to playlist" });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error modifying playlist" });
    }
};

export const removeSongFromPlaylist = async (req, res) => {
    const { id, songId } = req.params;
    const user_id = req.user.id;
    try {
        const playlist = await query(
            "SELECT * FROM playlists WHERE id = $1 AND creator_id = $2",
            [id, user_id],
        );
        if (playlist.rows.length === 0) {
            return res.status(403).json({ message: "Not authorized" });
        }
        const deleted = await query(
            "DELETE FROM playlist_songs WHERE playlist_id = $1 AND song_id = $2 RETURNING position",
            [id, songId],
        );
        if (deleted.rows.length === 0) {
            return res
                .status(404)
                .json({ message: "Song not found in playlist" });
        }
        await query(
            `UPDATE playlist_songs
             SET position = position - 1
             WHERE playlist_id = $1 AND position > $2`,
            [id, deleted.rows[0].position],
        );
        res.json({ message: "Song removed from playlist" });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error" });
    }
};

export const getPlaylistById = async (req, res) => {
    const { page = 1, limit = 100 } = req.query;
    const { limit: safeLimit, offset } = normalizePagination(
        page,
        limit,
        100,
        500,
    );
    try {
        const result = await query(
            "SELECT p.*, u.username as creator_name FROM playlists p JOIN users u ON p.creator_id = u.id WHERE p.id = $1",
            [req.params.id],
        );
        if (result.rows.length === 0)
            return res.status(404).json({ message: "Playlist not found" });

        const playlist = result.rows[0];
        if (
            !playlist.is_public &&
            (!req.user || req.user.id !== playlist.creator_id)
        ) {
            return res.status(403).json({ message: "Private playlist" });
        }

        const songs = await query(
            `
            SELECT ps.position, s.*, b.name as band_name,
            (SELECT COUNT(*) FROM likes WHERE song_id = s.id) as like_count
            FROM playlist_songs ps 
            JOIN songs s ON ps.song_id = s.id 
            JOIN bands b ON s.band_id = b.id
            WHERE ps.playlist_id = $1 
            ORDER BY ps.position ASC
            LIMIT $2 OFFSET $3
        `,
            [playlist.id, safeLimit, offset],
        );

        playlist.songs = songs.rows;
        res.json(playlist);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error" });
    }
};

export const updatePlaylist = async (req, res) => {
    const { title, description, is_public } = req.body;
    const playlistId = req.params.id;
    const userId = req.user.id;
    try {
        const playlist = await query(
            "SELECT * FROM playlists WHERE id = $1 AND creator_id = $2",
            [playlistId, userId],
        );
        if (playlist.rows.length === 0)
            return res.status(403).json({ message: "Not authorized" });

        let updateFields = [];
        let values = [];
        let paramIndex = 1;

        if (title) {
            updateFields.push(`title = $${paramIndex++}`);
            values.push(title);
        }
        if (description !== undefined) {
            updateFields.push(`description = $${paramIndex++}`);
            values.push(description);
        }
        if (is_public !== undefined) {
            updateFields.push(`is_public = $${paramIndex++}`);
            values.push(is_public);
        }

        if (req.files && req.files.cover_image) {
            updateFields.push(`cover_image = $${paramIndex++}`);
            values.push(`/uploads/images/${req.files.cover_image[0].filename}`);
        }

        if (updateFields.length === 0)
            return res.status(400).json({ message: "No fields to update" });

        values.push(playlistId);
        const result = await query(
            `UPDATE playlists SET ${updateFields.join(", ")} WHERE id = $${paramIndex} RETURNING *`,
            values,
        );
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error" });
    }
};

export const deletePlaylist = async (req, res) => {
    const playlistId = req.params.id;
    const userId = req.user.id;
    try {
        const playlist = await query(
            "SELECT * FROM playlists WHERE id = $1 AND creator_id = $2",
            [playlistId, userId],
        );
        if (playlist.rows.length === 0)
            return res.status(403).json({ message: "Not authorized" });

        await query("DELETE FROM playlists WHERE id = $1", [playlistId]);
        res.json({ message: "Playlist deleted" });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error" });
    }
};

export const getPlaylistShareInfo = async (req, res) => {
    try {
        const playlist = await query(
            "SELECT id, title, is_public FROM playlists WHERE id = $1",
            [req.params.id],
        );
        if (playlist.rows.length === 0)
            return res.status(404).json({ message: "Playlist not found" });
        if (!playlist.rows[0].is_public)
            return res
                .status(403)
                .json({ message: "Only public playlists can be shared" });

        res.json({
            playlist_id: playlist.rows[0].id,
            title: playlist.rows[0].title,
            share_url: `/playlists/${playlist.rows[0].id}`,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error generating share url" });
    }
};

export const reorderPlaylistSongs = async (req, res) => {
    const playlistId = Number.parseInt(req.params.id, 10);
    const userId = req.user.id;
    const { song_ids } = req.body;

    if (Number.isNaN(playlistId)) {
        return res.status(400).json({ message: "Invalid playlist id" });
    }
    if (!Array.isArray(song_ids) || song_ids.length === 0) {
        return res.status(400).json({ message: "song_ids array is required" });
    }

    try {
        const playlist = await query(
            "SELECT * FROM playlists WHERE id = $1 AND creator_id = $2",
            [playlistId, userId],
        );
        if (playlist.rows.length === 0)
            return res.status(403).json({ message: "Not authorized" });

        const existing = await query(
            "SELECT song_id FROM playlist_songs WHERE playlist_id = $1 ORDER BY position ASC",
            [playlistId],
        );
        const existingIds = existing.rows.map((row) =>
            Number.parseInt(row.song_id, 10),
        );
        const incomingIds = song_ids.map((id) => Number.parseInt(id, 10));

        const hasInvalidIncoming = incomingIds.some((id) => Number.isNaN(id));
        if (hasInvalidIncoming) {
            return res
                .status(400)
                .json({ message: "song_ids must contain valid song ids" });
        }

        if (existingIds.length !== incomingIds.length) {
            return res.status(400).json({
                message:
                    "song_ids must include all playlist songs exactly once",
            });
        }
        const existingSet = new Set(existingIds);
        const incomingSet = new Set(incomingIds);
        if (
            existingSet.size !== incomingSet.size ||
            [...existingSet].some((id) => !incomingSet.has(id))
        ) {
            return res.status(400).json({
                message:
                    "song_ids must include all playlist songs exactly once",
            });
        }

        await query("BEGIN");
        for (let index = 0; index < incomingIds.length; index += 1) {
            await query(
                "UPDATE playlist_songs SET position = $1 WHERE playlist_id = $2 AND song_id = $3",
                [index + 1, playlistId, incomingIds[index]],
            );
        }
        await query("COMMIT");

        res.json({ message: "Playlist order updated" });
    } catch (error) {
        await query("ROLLBACK");
        console.error(error);
        res.status(500).json({
            message: "Server error reordering playlist songs",
        });
    }
};
