import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import { upload } from "../middleware/uploadMiddleware.js";
import { updateUserImage } from "../controllers/userController.js";

const router = express.Router();

router.put(
    "/:id",
    protect,
    upload.fields([{ name: "profile_image", maxCount: 1 }]),
    updateUserImage
);

export default router;
