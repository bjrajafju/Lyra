import multer from 'multer';
import path from 'path';
import fs from 'fs';

// Ensure directories exist
const ensureDir = (dirPath) => {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
    }
};

ensureDir('uploads/audio');
ensureDir('uploads/images');
ensureDir('uploads/covers');

const storage = multer.diskStorage({
    destination(req, file, cb) {
        if (file.fieldname === 'audio') {
            cb(null, 'uploads/audio/');
        } else if (file.fieldname === 'cover_image' || file.fieldname === 'profile_image' || file.fieldname === 'banner_image') {
            cb(null, 'uploads/images/');
        } else {
            cb(null, 'uploads/');
        }
    },
    filename(req, file, cb) {
        cb(null, `${file.fieldname}-${Date.now()}${path.extname(file.originalname)}`);
    }
});

const checkFileType = (file, cb) => {
    const filetypes = /jpeg|jpg|png|mp3|wav|ogg/;
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = filetypes.test(file.mimetype);

    if (extname && mimetype) {
        return cb(null, true);
    } else {
        cb(new Error('Images and Audio files only!'));
    }
};

export const upload = multer({
    storage,
    limits: { fileSize: 50 * 1024 * 1024 }, // 50MB max file size
    fileFilter: function (req, file, cb) {
        checkFileType(file, cb);
    }
});
