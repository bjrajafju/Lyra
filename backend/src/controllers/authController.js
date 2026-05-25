import bcrypt from "bcrypt";
import { query } from "../db/index.js";
import { generateToken } from "../utils/jwt.js";

export const registerUser = async (req, res) => {
    const { username, email, password, role } = req.body;
    try {
        const userExists = await query(
            "SELECT id FROM users WHERE email = $1 OR username = $2",
            [email, username],
        );
        if (userExists.rows.length > 0) {
            return res.status(400).json({ message: "User already exists" });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);
        const userRole = role === "artist" ? "artist" : "listener";

        const newUser = await query(
            "INSERT INTO users (username, email, password_hash, role) VALUES ($1, $2, $3, $4) RETURNING id, username, email, role",
            [username, email, hashedPassword, userRole],
        );
        const user = newUser.rows[0];
        const token = generateToken(user.id, user.role);

        res.status(201).json({
            id: user.id,
            username: user.username,
            email: user.email,
            role: user.role,
            token,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error" });
    }
};

export const loginUser = async (req, res) => {
    const { email, password } = req.body;
    try {
        const result = await query("SELECT * FROM users WHERE email = $1", [
            email,
        ]);
        if (result.rows.length === 0) {
            return res.status(401).json({ message: "Invalid credentials" });
        }

        const user = result.rows[0];
        const isMatch = await bcrypt.compare(password, user.password_hash);

        if (!isMatch) {
            return res.status(401).json({ message: "Invalid credentials" });
        }

        const token = generateToken(user.id, user.role);
        res.json({
            id: user.id,
            username: user.username,
            email: user.email,
            role: user.role,
            profile_picture: user.profile_picture,
            bio: user.bio,
            token,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error" });
    }
};

export const getUserProfile = async (req, res) => {
    try {
        const result = await query(
            "SELECT id, username, email, profile_picture, bio, role, created_at FROM users WHERE id = $1",
            [req.user.id],
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ message: "User not found" });
        }
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error" });
    }
};

export const getUserById = async (req, res) => {
    try {
        const result = await query(
            "SELECT id, username, email, profile_picture, bio, role, created_at FROM users WHERE id = $1",
            [req.params.id],
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ message: "User not found" });
        }

        const user = result.rows[0];

        // Get follower count
        const followers = await query(
            "SELECT COUNT(*) FROM user_follows WHERE followed_user_id = $1",
            [req.params.id],
        );
        user.follower_count = parseInt(followers.rows[0].count);

        // Get following count
        const following = await query(
            "SELECT COUNT(*) FROM user_follows WHERE follower_id = $1",
            [req.params.id],
        );
        user.following_count = parseInt(following.rows[0].count);

        res.json(user);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error" });
    }
};

export const updateProfile = async (req, res) => {
    const { username, bio } = req.body;
    const userId = req.user.id;
    try {
        let profile_picture = null;
        if (req.files && req.files.profile_picture) {
            profile_picture = `/uploads/images/${req.files.profile_picture[0].filename}`;
        }

        let updateFields = [];
        let values = [];
        let paramIndex = 1;

        if (username) {
            updateFields.push(`username = $${paramIndex++}`);
            values.push(username);
        }
        if (bio !== undefined) {
            updateFields.push(`bio = $${paramIndex++}`);
            values.push(bio);
        }
        if (profile_picture) {
            updateFields.push(`profile_picture = $${paramIndex++}`);
            values.push(profile_picture);
        }

        if (updateFields.length === 0) {
            return res.status(400).json({ message: "No fields to update" });
        }

        values.push(userId);
        const result = await query(
            `UPDATE users SET ${updateFields.join(", ")} WHERE id = $${paramIndex} RETURNING id, username, email, profile_picture, bio, role`,
            values,
        );
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error updating profile" });
    }
};

export const deleteAccount = async (req, res) => {
    try {
        await query("DELETE FROM users WHERE id = $1", [req.user.id]);
        res.json({ message: "Account deleted successfully" });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server error deleting account" });
    }
};

export const getContext = async (req, res) => {
    try {
        const userResult = await query(
            "SELECT id, username, email, profile_picture, bio, role FROM users WHERE id = $1",
            [req.user.id],
        );
        if (userResult.rows.length === 0) {
            return res.status(404).json({ message: "User not found" });
        }

        const bandsResult = await query(
            `
            SELECT b.id, b.name, b.profile_image, bm.role_in_band as role
            FROM bands b
            JOIN band_members bm ON b.id = bm.band_id
            WHERE bm.user_id = $1 AND bm.role_in_band IN ('admin', 'editor')
            ORDER BY b.name ASC
        `,
            [req.user.id],
        );

        res.json({
            user: userResult.rows[0],
            bands: bandsResult.rows,
        });
    } catch (error) {
        console.error("Error fetching context:", error);
        res.status(500).json({ message: "Server error" });
    }
};
