import { Router } from 'express';
import multer from 'multer';
import path from 'node:path';
import { randomUUID } from 'node:crypto';
import { authenticate } from '../../middlewares/auth.middleware.js';
import { requireRoles } from '../../middlewares/rbac.middleware.js';
import { env } from '../../config/env.js';
import * as uploadController from './upload.controller.js';

const storage = multer.diskStorage({
  destination: env.UPLOAD_LOCAL_DIR,
  filename: (_req, file, callback) => {
    callback(null, `${randomUUID()}${path.extname(file.originalname)}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 150 * 1024 * 1024 }
});

export const uploadRouter = Router();

uploadRouter.use(authenticate);
uploadRouter.post('/parcel-photo', uploadController.uploadBase64);
uploadRouter.post('/parcel-video', uploadController.uploadBase64);
uploadRouter.post('/parcel-audio', uploadController.uploadBase64);
uploadRouter.post('/bid-audio', requireRoles('driver'), uploadController.uploadBase64);
uploadRouter.post('/base64', uploadController.uploadBase64);
uploadRouter.post('/', upload.single('file'), uploadController.uploadMultipart);
