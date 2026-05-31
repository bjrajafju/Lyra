import { query } from "../db/index.js";

export const updateUserImage = async (req, res) => {
    const userId = req.params.id;

    // Authorization check
    if (parseInt(userId) !== req.user.id) {
        return res.status(403).json({ message: "Not authorized to update this user" });
    }

    try {
        let profile_picture = null;
        if (req.files && req.files.profile_image) {
            profile_picture = `/uploads/images/${req.files.profile_image[0].filename}`;
        }

        if (!profile_picture) {
            return res.status(400).json({ message: "No profile_image provided" });
        }

        const result = await query(
            `UPDATE users SET profile_picture = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING id, username, email, profile_picture, bio, role`,
            [profile_picture, userId]
        );

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error updating user profile image" });
    }
};
