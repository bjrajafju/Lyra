import { verifyToken } from '../utils/jwt.js';

export const protect = (req, res, next) => {
    let token;
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            token = req.headers.authorization.split(' ')[1];
            const decoded = verifyToken(token);
            req.user = decoded; // { id, role }
            next();
        } catch (error) {
            console.error(error);
            res.status(401).json({ message: 'Not authorized, token failed' });
        }
    } else {
        res.status(401).json({ message: 'Not authorized, no token' });
    }
};

export const artistOnly = (req, res, next) => {
    if (req.user && req.user.role === 'artist') {
        next();
    } else {
        res.status(403).json({ message: 'Not authorized as an artist' });
    }
};
