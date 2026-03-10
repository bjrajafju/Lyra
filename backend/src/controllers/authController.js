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
        console.log("passou do response"); // passa
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
            "SELECT id, username, email, profile_picture, bio, role FROM users WHERE id = $1",
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
