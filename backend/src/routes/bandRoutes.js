import express from "express";
import {
    createBand,
    getBands,
    getBandById,
    updateBand,
    deleteBand,
    getUserBands,
} from "../controllers/bandController.js";
import {
    protect,
    artistOnly,
    checkBandRole,
} from "../middleware/authMiddleware.js";
import { upload } from "../middleware/uploadMiddleware.js";
import memberRoutes from "./memberRoutes.js";
import widgetRoutes from "./widgetRoutes.js";
import songRoutes from "./songRoutes.js";
import albumRoutes from "./albumRoutes.js";

const router = express.Router();

router.get("/my-bands", protect, getUserBands);

// Nest member management
router.use("/:bandId/members", memberRoutes);

// Nest widget management
router.use("/:bandId/widgets", widgetRoutes);

// Nest song management under band
router.use("/:bandId/songs", (req, res, next) => {
    req.query.bandId = req.params.bandId;
    next();
}, songRoutes);

// Nest album management under band
router.use("/:bandId/albums", (req, res, next) => {
    req.query.bandId = req.params.bandId;
    next();
}, albumRoutes);

router
    .route("/")
    .get(getBands)
    .post(
        protect,
        artistOnly,
        upload.fields([
            { name: "profile_image", maxCount: 1 },
            { name: "banner_image", maxCount: 1 },
        ]),
        createBand,
    );

router
    .route("/:id")
    .get(getBandById)
    .put(
        protect,
        checkBandRole("editor"),
        upload.fields([
            { name: "profile_image", maxCount: 1 },
            { name: "banner_image", maxCount: 1 },
        ]),
        updateBand,
    )
    .delete(protect, checkBandRole("admin"), deleteBand);

export default router;
