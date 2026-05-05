import multer from "multer";
import path from "path";
import fs from "fs";

// Ensure directories exist
const ensureDir = (dirPath) => {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
    }
};

ensureDir("uploads/audio");
ensureDir("uploads/images");
ensureDir("uploads/covers");

const storage = multer.diskStorage({
    destination(req, file, cb) {
        if (file.fieldname === "audio") {
            cb(null, "uploads/audio/");
        } else if (
            file.fieldname === "cover_image" ||
            file.fieldname === "profile_image" ||
            file.fieldname === "banner_image"
        ) {
            cb(null, "uploads/images/");
        } else {
            cb(null, "uploads/");
        }
    },
    filename(req, file, cb) {
        cb(
            null,
            `${file.fieldname}-${Date.now()}${path.extname(file.originalname)}`,
        );
    },
});

const checkFileType = (file, cb) => {
    // For file extension
    const extname = /jpeg|jpg|png|mp3|wav|ogg|m4a|aac/.test(
        path.extname(file.originalname).toLowerCase(),
    );

    // For MIME type (Flutter web bytes often send application/octet-stream, standard audio is often audio/mpeg)
    const mimetype =
        /jpeg|jpg|png|mpeg|mp3|wav|ogg|audio|image|octet-stream/.test(
            file.mimetype,
        );

    if (extname && mimetype) {
        return cb(null, true);
    } else {
        cb(
            new Error(
                `Images and Audio files only! Uploaded mimetype: ${file.mimetype}`,
            ),
        );
    }
};

export const upload = multer({
    storage,
    limits: { fileSize: 50 * 1024 * 1024 }, // 50MB max file size
    fileFilter: function (req, file, cb) {
        checkFileType(file, cb);
    },
});
