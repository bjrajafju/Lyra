import express from "express";
import {
    getBandMembers,
    updateMemberRole,
    removeMember,
    leaveBand,
} from "../controllers/membersController.js";
import { protect, checkBandRole } from "../middleware/authMiddleware.js";

const router = express.Router({ mergeParams: true });

// All member routes require being at least a member
router.get("/", protect, checkBandRole("member"), getBandMembers);

// Member-only routes
router.delete("/leave", protect, leaveBand);

// Editor/Admin routes
router.patch(
    "/:userId/role",
    protect,
    checkBandRole("editor"),
    updateMemberRole,
);
router.delete("/:userId", protect, checkBandRole("editor"), removeMember);

export default router;
