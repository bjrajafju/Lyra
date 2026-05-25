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

export const optionalProtect = (req, res, next) => {
    if (
        req.headers.authorization &&
        req.headers.authorization.startsWith("Bearer")
    ) {
        try {
            const token = req.headers.authorization.split(" ")[1];
            const decoded = verifyToken(token);
            req.user = decoded;
        } catch (error) {
            // Silently fail for optional protect
        }
    }
    next();
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
        let bandId =
            req.params.bandId ||
            req.query.bandId ||
            req.query.band_id ||
            (req.body ? req.body.band_id || req.body.bandId : null);
        const userId = req.user.id;

        // If bandId is not directly provided, try to infer it from resource ID
        if (!bandId && req.params.id) {
            const resourceId = req.params.id;
            const path = req.baseUrl + req.path;

            try {
                if (path.includes("/songs")) {
                    const songRes = await query(
                        "SELECT band_id FROM songs WHERE id = $1",
                        [resourceId],
                    );
                    if (songRes.rows.length > 0)
                        bandId = songRes.rows[0].band_id;
                } else if (path.includes("/albums")) {
                    const albumRes = await query(
                        "SELECT band_id FROM albums WHERE id = $1",
                        [resourceId],
                    );
                    if (albumRes.rows.length > 0)
                        bandId = albumRes.rows[0].band_id;
                } else if (path.includes("/bands")) {
                    // Check if the path is exactly /bands/:id or /bands/:id/...
                    // If it's something like /bands/my-bands, req.params.id won't be set to a band ID
                    bandId = resourceId;
                }
            } catch (error) {
                console.error("Error inferring bandId:", error);
            }
        }

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
