import express from "express";
import {
  getBandAnalytics,
  getSongStats,
} from "../controllers/analyticsController.js";
import { protect, checkBandRole } from "../middleware/authMiddleware.js";

const router = express.Router();

router.get("/:bandId", protect, checkBandRole("member"), getBandAnalytics);
router.get(
  "/:bandId/song-stats",
  protect,
  checkBandRole("member"),
  getSongStats,
);

export default router;
