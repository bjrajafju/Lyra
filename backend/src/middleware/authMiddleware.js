import { verifyToken } from "../utils/jwt.js";
import { query } from "../db/index.js";

export const protect = (req, res, next) => {
    let token;
    if (
        req.headers.authorization &&
        req.headers.authorization.startsWith("Bearer")
    ) {
        try {
            token = req.headers.authorization.split(" ")[1];
            const decoded = verifyToken(token);
            req.user = decoded; // { id, role }
            next();
        } catch (error) {
            console.error(error);
            res.status(401).json({ message: "Not authorized, token failed" });
        }
    } else {
        res.status(401).json({ message: "Not authorized, no token" });
    }
};

export const artistOnly = (req, res, next) => {
    if (req.user && req.user.role === "artist") {
        next();
    } else {
        res.status(403).json({ message: "Not authorized as an artist" });
    }
};

export const checkBandRole = (requiredRole) => {
    return async (req, res, next) => {
        const bandId =
            req.params.bandId ||
            req.params.id ||
            req.query.bandId ||
            (req.body ? req.body.band_id : null);
        const userId = req.user.id;

        if (!bandId) {
            return res.status(400).json({ message: "Band ID is required" });
        }

        try {
            const result = await query(
                "SELECT role_in_band FROM band_members WHERE band_id = $1 AND user_id = $2",
                [bandId, userId],
            );

            if (result.rows.length === 0) {
                return res
                    .status(403)
                    .json({ message: "Not a member of this band" });
            }

            const userRole = result.rows[0].role_in_band;

            // Role hierarchy: admin > editor > member
            const roleHierarchy = { admin: 3, editor: 2, member: 1 };

            if (roleHierarchy[userRole] < roleHierarchy[requiredRole]) {
                return res
                    .status(403)
                    .json({ message: `Requires ${requiredRole} role` });
            }

            req.bandRole = userRole; // Store role for further use
            next();
        } catch (error) {
            console.error(error);
            res.status(500).json({
                message: "Server error during role validation",
            });
        }
    };
};
