import express from "express";
import {
    searchAll,
    getDiscovery,
    searchUsers,
    getGenres,
} from "../controllers/searchController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.get("/", searchAll);
router.get("/discovery", getDiscovery);
router.get("/users", protect, searchUsers);
router.get("/genres", getGenres);

export default router;
