import { query } from "../db/index.js";

export const uploadSong = async (req, res) => {
    const {
        band_id,
        album_id,
        title,
        description,
        duration,
        release_date,
        genre_ids,
        tags,
    } = req.body;
    const uploaded_by = req.user.id;

    if (!req.files || !req.files.audio) {
        return res.status(400).json({ message: "Audio file is required" });
    }

    // Validation: Image size (Multer handles total, but we can check here for image specifically)
    if (
        req.files.cover_image &&
        req.files.cover_image[0].size > 5 * 1024 * 1024
    ) {
        return res
            .status(400)
            .json({ message: "Cover image must be less than 5MB" });
    }

    try {
        const audio_url = `/uploads/audio/${req.files.audio[0].filename}`;
        let cover_image = null;
        if (req.files.cover_image) {
            cover_image = `/uploads/images/${req.files.cover_image[0].filename}`;
        }

        let parsedTags = null;
        if (tags) {
            if (typeof tags === "string") {
                try {
                    parsedTags = JSON.parse(tags);
                } catch (e) {
                    parsedTags = tags.split(",").map(t => t.trim()).filter(Boolean);
                }
            } else if (Array.isArray(tags)) {
                parsedTags = tags;
            }
        }

        const newSongResult = await query(
            `INSERT INTO songs 
            (band_id, uploaded_by, title, description, audio_url, cover_image, duration, release_date, status, tags) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING *`,
            [
                band_id,
                uploaded_by,
                title,
                description,
                audio_url,
                cover_image,
                duration || 0,
                release_date || null,
                "draft",
                parsedTags ? JSON.stringify(parsedTags) : null,
            ],
        );

        const song = newSongResult.rows[0];

        // Add genres
        let parsedGenreIds = genre_ids;
        if (typeof genre_ids === "string") {
            try {
                parsedGenreIds = JSON.parse(genre_ids);
            } catch (e) {}
        }
        if (parsedGenreIds && Array.isArray(parsedGenreIds)) {
            for (const genreId of parsedGenreIds) {
                await query(
                    "INSERT INTO songs_genres (song_id, genre_id) VALUES ($1, $2)",
                    [song.id, genreId],
                );
            }
        }

        // Add to album if provided
        if (album_id) {
            const posResult = await query(
                "SELECT COALESCE(MAX(position), 0) + 1 as next_pos FROM album_songs WHERE album_id = $1",
                [album_id],
            );
            await query(
                "INSERT INTO album_songs (album_id, song_id, position) VALUES ($1, $2, $3)",
                [album_id, song.id, posResult.rows[0].next_pos],
            );
        }

        res.status(201).json(song);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error uploading song" });
    }
};

export const getSongs = async (req, res) => {
    const { page = 1, limit = 20, band_id, sort = "recent" } = req.query;
    const offset = (page - 1) * limit;
    const orderBy =
        sort === "popular"
            ? "s.play_count DESC, s.created_at DESC"
            : "s.created_at DESC";

    try {
        let sql = `
            SELECT s.*, b.name as band_name,
            (SELECT json_agg(g.*) FROM genres g JOIN songs_genres sg ON g.id = sg.genre_id WHERE sg.song_id = s.id) as genres,
            (SELECT album_id FROM album_songs WHERE song_id = s.id LIMIT 1) as album_id,
            (SELECT COUNT(*) FROM likes WHERE song_id = s.id) as like_count
            FROM songs s JOIN bands b ON s.band_id = b.id 
            WHERE s.status = 'published'
        `;
        let params = [limit, offset];

        if (band_id) {
            sql += " AND s.band_id = $3";
            params.push(band_id);
        }

        sql += ` ORDER BY ${orderBy} LIMIT $1 OFFSET $2`;

        const result = await query(sql, params);
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Error fetching songs" });
    }
};

export const getMySongs = async (req, res) => {
    const { bandId } = req.query; // Usually passed from dashboard
    if (!bandId) return res.status(400).json({ message: "bandId is required" });

    try {
        const result = await query(
            `
            SELECT s.*,
            (SELECT json_agg(g.*) FROM genres g JOIN songs_genres sg ON g.id = sg.genre_id WHERE sg.song_id = s.id) as genres,
            (SELECT album_id FROM album_songs WHERE song_id = s.id LIMIT 1) as album_id,
            (SELECT COUNT(*) FROM likes WHERE song_id = s.id) as like_count,
            (SELECT COUNT(*) FROM favorites WHERE song_id = s.id) as favorite_count,
            (SELECT COUNT(*) FROM playlist_songs WHERE song_id = s.id) as playlist_additions
            FROM songs s WHERE s.band_id = $1 ORDER BY s.created_at DESC
        `,
            [bandId],
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Error fetching management songs" });
    }
};

export const toggleSongStatus = async (req, res) => {
    const { id } = req.params;
    let { status } = req.body;

    try {
        if (!status) {
            const current = await query(
                "SELECT status FROM songs WHERE id = $1",
                [id],
            );
            if (current.rows.length === 0)
                return res.status(404).json({ message: "Song not found" });
            status =
                current.rows[0].status === "published" ? "draft" : "published";
        }

        if (!["published", "draft"].includes(status)) {
            return res.status(400).json({ message: "Invalid status" });
        }

        let updateSql =
            "UPDATE songs SET status = $1, updated_at = CURRENT_TIMESTAMP";
        let params = [status, id];

        if (status === "published") {
            updateSql +=
                ", release_date = COALESCE(release_date, CURRENT_DATE)";
        }

        updateSql += " WHERE id = $2 RETURNING *";

        const result = await query(updateSql, params);
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Error toggling status" });
    }
};

export const deleteSong = async (req, res) => {
    const { id } = req.params;
    try {
        // Cascade delete is handled by DB schema (likes, comments, streams, album_songs, playlist_songs)
        const result = await query(
            "DELETE FROM songs WHERE id = $1 RETURNING *",
            [id],
        );
        if (result.rows.length === 0)
            return res.status(404).json({ message: "Song not found" });
        res.json({ message: "Song deleted successfully" });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Error deleting song" });
    }
};

export const getSongById = async (req, res) => {
    const { id } = req.params;
    try {
        const result = await query(
            `
            SELECT s.*, b.name as band_name,
            (SELECT json_agg(g.*) FROM genres g JOIN songs_genres sg ON g.id = sg.genre_id WHERE sg.song_id = s.id) as genres,
            (SELECT album_id FROM album_songs WHERE song_id = s.id LIMIT 1) as album_id,
            (SELECT COUNT(*) FROM likes WHERE song_id = s.id) as like_count
            FROM songs s JOIN bands b ON s.band_id = b.id WHERE s.id = $1
        `,
            [id],
        );

        if (result.rows.length === 0)
            return res.status(404).json({ message: "Song not found" });
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Error fetching song" });
    }
};

export const updateSong = async (req, res) => {
    const { id } = req.params;
    const { title, description, genre_ids, tags, album_id, status, release_date } = req.body;

    try {
        let updateFields = ["updated_at = CURRENT_TIMESTAMP"];
        let params = [id];
        let pIndex = 2;

        if (title) {
            updateFields.push(`title = $${pIndex++}`);
            params.push(title);
        }
        if (description !== undefined) {
            updateFields.push(`description = $${pIndex++}`);
            params.push(description);
        }
        if (tags !== undefined) {
            let parsedTags = null;
            if (tags) {
                if (typeof tags === "string") {
                    try {
                        parsedTags = JSON.parse(tags);
                    } catch (e) {
                        parsedTags = tags.split(",").map(t => t.trim()).filter(Boolean);
                    }
                } else if (Array.isArray(tags)) {
                    parsedTags = tags;
                }
            }
            updateFields.push(`tags = $${pIndex++}`);
            params.push(parsedTags ? JSON.stringify(parsedTags) : null);
        }
        if (release_date !== undefined) {
            updateFields.push(`release_date = $${pIndex++}`);
            params.push(release_date || null);
        } else if (status === "published") {
            updateFields.push(
                `release_date = COALESCE(release_date, CURRENT_DATE)`,
            );
        }
        if (status) {
            updateFields.push(`status = $${pIndex++}`);
            params.push(status);
        }

        if (req.files && req.files.cover_image) {
            updateFields.push(`cover_image = $${pIndex++}`);
            params.push(`/uploads/images/${req.files.cover_image[0].filename}`);
        }

        const sql = `UPDATE songs SET ${updateFields.join(", ")} WHERE id = $1 RETURNING *`;
        const result = await query(sql, params);

        if (result.rows.length === 0)
            return res.status(404).json({ message: "Song not found" });

        const song = result.rows[0];

        // Update album relation if provided
        if (album_id !== undefined) {
            // Remove from current albums (if system supports only one album per song)
            await query("DELETE FROM album_songs WHERE song_id = $1", [id]);

            if (album_id && album_id !== "" && album_id !== "null") {
                const posResult = await query(
                    "SELECT COALESCE(MAX(position), 0) + 1 as next_pos FROM album_songs WHERE album_id = $1",
                    [album_id],
                );
                await query(
                    "INSERT INTO album_songs (album_id, song_id, position) VALUES ($1, $2, $3)",
                    [album_id, id, posResult.rows[0].next_pos],
                );
            }
        }
        let parsedGenreIds = genre_ids;
        if (typeof genre_ids === "string") {
            try {
                parsedGenreIds = JSON.parse(genre_ids);
            } catch (e) {}
        }
        if (parsedGenreIds && Array.isArray(parsedGenreIds)) {
            await query("DELETE FROM songs_genres WHERE song_id = $1", [id]);
            for (const genreId of parsedGenreIds) {
                await query(
                    "INSERT INTO songs_genres (song_id, genre_id) VALUES ($1, $2)",
                    [id, genreId],
                );
            }
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Error updating song" });
    }
};

export const playSong = async (req, res) => {
    const { id } = req.params;
    try {
        await query(
            "UPDATE songs SET play_count = play_count + 1 WHERE id = $1",
            [id],
        );
        await query("INSERT INTO streams (song_id, user_id) VALUES ($1, $2)", [
            id,
            req.user ? req.user.id : null,
        ]);
        res.json({ message: "Stream recorded" });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Error recording stream" });
    }
};
