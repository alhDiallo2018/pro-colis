import fs from 'node:fs/promises';
import path from 'node:path';
import { randomUUID } from 'node:crypto';
import { env } from '../../config/env.js';
import { prisma } from '../../config/prisma.js';
import { ok, fail } from '../../utils/api-response.js';

const allowedMimeTypes = {
  photo: ['image/jpeg', 'image/png', 'image/webp'],
  video: ['video/mp4', 'video/quicktime', 'video/webm'],
  audio: ['audio/mp4', 'audio/aac', 'audio/mpeg', 'audio/wav', 'audio/webm']
};

function getMediaType(routeName) {
  if (routeName.includes('video')) return 'video';
  if (routeName.includes('audio')) return 'audio';
  return 'photo';
}

async function persistBase64File({ file, filename, mediaType }) {
  const uploadDir = path.resolve(env.UPLOAD_LOCAL_DIR, mediaType);
  await fs.mkdir(uploadDir, { recursive: true });

  const extension = path.extname(filename || '').toLowerCase() || '.bin';
  const safeFilename = `${randomUUID()}${extension}`;
  const diskPath = path.join(uploadDir, safeFilename);

  // Strip data URL metadata when mobile sends "data:mime/type;base64,..." payloads.
  const base64Payload = file.includes(',') ? file.split(',').pop() : file;
  await fs.writeFile(diskPath, Buffer.from(base64Payload, 'base64'));

  return `${env.PUBLIC_BASE_URL}/${env.UPLOAD_LOCAL_DIR}/${mediaType}/${safeFilename}`;
}

export async function uploadBase64(req, res) {
  try {
    const mediaType = getMediaType(req.path);
    const { file, filename, parcelId } = req.body;

    if (!file) {
      return fail(res, {
        status: 422,
        message: 'Fichier manquant',
        code: 'VALIDATION_ERROR',
        details: [{ path: 'file', message: 'Required' }]
      });
    }

    const url = await persistBase64File({ file, filename, mediaType });
    let media = null;

    if (parcelId) {
      media = await prisma.parcelMedia.create({
        data: {
          parcelId,
          uploadedBy: req.user.id,
          mediaType,
          url,
          filename
        }
      });
    }

    return ok(res, {
      status: 201,
      message: 'Fichier envoye',
      data: { url, media }
    });
  } catch (error) {
    req.log.error(
      {
        error,
        action: 'upload.base64',
        userId: req.user?.id,
        requestId: req.requestId
      },
      'Failed to upload base64 file'
    );

    return fail(res, { status: 500, message: 'Impossible de traiter le fichier' });
  }
}

export async function uploadMultipart(req, res) {
  try {
    const mediaType = req.body.mediaType || 'photo';
    // Normalise e.g. "audio/webm;codecs=opus" -> "audio/webm" before checking.
    const baseMime = (req.file?.mimetype || '').split(';')[0].trim();
    const mimeAllowed = allowedMimeTypes[mediaType]?.includes(baseMime);

    if (!req.file || !mimeAllowed) {
      return fail(res, {
        status: 422,
        message: 'Type de fichier invalide',
        code: 'VALIDATION_ERROR'
      });
    }

    const url = `${env.PUBLIC_BASE_URL}/${env.UPLOAD_LOCAL_DIR}/${req.file.filename}`;
    let media = null;
    const { parcelId } = req.body;

    if (parcelId) {
      media = await prisma.parcelMedia.create({
        data: {
          parcelId,
          uploadedBy: req.user.id,
          mediaType,
          url,
          filename: req.file.originalname
        }
      });
    }

    return ok(res, {
      status: 201,
      message: 'Fichier envoye',
      data: { url, media }
    });
  } catch (error) {
    req.log.error(
      { error, action: 'upload.multipart', userId: req.user?.id, requestId: req.requestId },
      'Failed to upload multipart file'
    );

    return fail(res, { status: 500, message: 'Impossible de traiter le fichier' });
  }
}
