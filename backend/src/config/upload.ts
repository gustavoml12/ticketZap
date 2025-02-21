import path from "path";
import multer from "multer";

const uploadsFolder = process.env.UPLOAD_DIR || path.resolve("/usr/src/app", "uploads");
const publicFolder = process.env.PUBLIC_DIR || path.resolve("/usr/src/app", "public");

export default {
  uploadsDirectory: uploadsFolder,
  publicDirectory: publicFolder,

  storage: multer.diskStorage({
    destination: (req, file, cb) => {
      // Se for um upload do sistema (logos, etc), vai para public
      // Senão vai para uploads
      const isSystemUpload = req.path.includes('/system') || req.query.type === 'system';
      const destination = isSystemUpload ? publicFolder : uploadsFolder;
      return cb(null, destination);
    },
    filename(req, file, cb) {
      const fileName = new Date().getTime() + path.extname(file.originalname);
      return cb(null, fileName);
    }
  })
};
