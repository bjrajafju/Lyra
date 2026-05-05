import { query } from "../db/index.js";

export const addComment = async (req, res) => {
    const { song_id, text } = req.body;
    const user_id = req.user.id;
    try {
        const result = await query(
            "INSERT INTO comments (user_id, song_id, text) VALUES ($1, $2, $3) RETURNING *",
            [user_id, song_id, text],
        );
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error adding comment" });
    }
};

export const getComments = async (req, res) => {
    const { song_id } = req.params;
    try {
        const result = await query(
            `
            SELECT c.*, u.username, u.profile_picture 
            FROM comments c 
            JOIN users u ON c.user_id = u.id 
            WHERE c.song_id = $1 
            ORDER BY c.created_at DESC
        `,
            [song_id],
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error fetching comments" });
    }
};

export const deleteComment = async (req, res) => {
    const { id } = req.params;
    const user_id = req.user.id;
    try {
        // Only comment author or the song's band member can delete
        const comment = await query("SELECT * FROM comments WHERE id = $1", [
            id,
        ]);
        if (comment.rows.length === 0)
            return res.status(404).json({ message: "Comment not found" });

        const commentData = comment.rows[0];
        if (commentData.user_id === user_id) {
            await query("DELETE FROM comments WHERE id = $1", [id]);
            return res.json({ message: "Comment deleted" });
        }

        // Check if user is in the band that owns the song
        const bandCheck = await query(
            `
            SELECT bm.role_in_band 
            FROM band_members bm 
            JOIN songs s ON bm.band_id = s.band_id 
            WHERE s.id = $1 AND bm.user_id = $2
        `,
            [commentData.song_id, user_id],
        );

        if (bandCheck.rows.length > 0) {
            await query("DELETE FROM comments WHERE id = $1", [id]);
            return res.json({ message: "Comment deleted by artist" });
        }

        res.status(403).json({
            message: "Not authorized to delete this comment",
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error deleting comment" });
    }
};
