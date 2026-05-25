import express from "express";
import {
    getBandWidgets,
    getPublicBandLayout,
    createWidget,
    updateWidget,
    deleteWidget,
    reorderWidgets,
} from "../controllers/widgetController.js";
import { protect, checkBandRole } from "../middleware/authMiddleware.js";

const router = express.Router({ mergeParams: true });

// Publicly viewable
router.get("/", getPublicBandLayout);

// Protected (requires Editor role)
router.get("/all", protect, checkBandRole("editor"), getBandWidgets);

// Protected (requires Editor role)
router.post("/", protect, checkBandRole("editor"), createWidget);
router.patch("/reorder", protect, checkBandRole("editor"), reorderWidgets);
router.patch("/:widgetId", protect, checkBandRole("editor"), updateWidget);
router.delete("/:widgetId", protect, checkBandRole("editor"), deleteWidget);

export default router;
