import express from "express";
import {
    createInvitation,
    getBandInvitations,
    getUserInvitations,
    respondToInvitation,
} from "../controllers/invitationController.js";
import { protect, checkBandRole } from "../middleware/authMiddleware.js";

const router = express.Router();

// User routes (received invitations)
router.get("/my-invitations", protect, getUserInvitations);
router.post("/:invitationId/respond", protect, respondToInvitation);

// Band routes (sent invitations)
// checkBandRole('editor') allows both editors and admins
router.post(
    "/band/:bandId",
    protect,
    checkBandRole("editor"),
    createInvitation,
);
router.get(
    "/band/:bandId",
    protect,
    checkBandRole("editor"),
    getBandInvitations,
);

export default router;
