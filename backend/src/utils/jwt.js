import jwt from "jsonwebtoken";
import dotenv from "dotenv";
dotenv.config();

export const generateToken = (userId, role) => {
    return jwt.sign({ id: userId, role }, process.env.JWT_SECRET, {
        expiresIn: "30d",
    });
};

export const verifyToken = (token) => {
    return jwt.verify(token, process.env.JWT_SECRET);
};
