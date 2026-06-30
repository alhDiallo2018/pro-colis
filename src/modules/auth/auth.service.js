import bcrypt from 'bcryptjs';
import { prisma } from '../../config/prisma.js';
import { ConflictError, UnauthorizedError } from '../../utils/errors.js';
import {
  compareSecret,
  hashSecret,
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken
} from '../../utils/tokens.js';
import { serializeUser } from '../../utils/user-serializer.js';

function addDays(date, days) {
  const nextDate = new Date(date);
  nextDate.setDate(nextDate.getDate() + days);
  return nextDate;
}

async function createTokenPair(user) {
  const accessToken = signAccessToken(user);
  const refreshToken = signRefreshToken(user);
  const tokenHash = await hashSecret(refreshToken);

  await prisma.refreshToken.create({
    data: {
      userId: user.id,
      tokenHash,
      expiresAt: addDays(new Date(), 30)
    }
  });

  return { accessToken, refreshToken };
}

export async function registerUser(payload) {
  const existingUser = await prisma.user.findFirst({
    where: {
      OR: [{ phone: payload.phone }, ...(payload.email ? [{ email: payload.email }] : [])]
    }
  });

  if (existingUser) {
    throw new ConflictError('Un utilisateur existe deja avec ces informations');
  }

  const passwordHash = payload.password ? await bcrypt.hash(payload.password, 12) : null;
  const pinHash = payload.pin ? await bcrypt.hash(payload.pin, 12) : null;

  // Registration creates the user, initial score row and audit entry atomically.
  const user = await prisma.$transaction(async (tx) => {
    const createdUser = await tx.user.create({
      data: {
        email: payload.email,
        phone: payload.phone,
        fullName: payload.fullName,
        passwordHash,
        pinHash,
        role: payload.role,
        address: payload.address,
        city: payload.city,
        region: payload.region,
        garageId: payload.garageId,
        driverStatus: payload.role === 'driver' ? 'offline' : null,
        isProfileComplete: Boolean(payload.fullName && payload.phone)
      }
    });

    await tx.score.create({ data: { userId: createdUser.id } });
    await tx.auditLog.create({
      data: {
        actorId: createdUser.id,
        actorRole: createdUser.role,
        action: 'user.create',
        entityType: 'user',
        entityId: createdUser.id,
        afterData: { role: createdUser.role, phone: createdUser.phone }
      }
    });

    return createdUser;
  });

  const tokens = await createTokenPair(user);
  return { user: serializeUser(user), ...tokens };
}

export async function loginWithPin({ identifier, pin }) {
  const user = await prisma.user.findFirst({
    where: {
      OR: [{ phone: identifier }, { email: identifier }]
    }
  });

  if (!user || !user.pinHash || user.status !== 'active') {
    throw new UnauthorizedError('Identifiants invalides');
  }

  const pinMatches = await compareSecret(pin, user.pinHash);
  if (!pinMatches) {
    throw new UnauthorizedError('Identifiants invalides');
  }

  const updatedUser = await prisma.user.update({
    where: { id: user.id },
    data: { lastLogin: new Date(), lastActiveAt: new Date() }
  });

  const tokens = await createTokenPair(updatedUser);
  return { user: serializeUser(updatedUser), ...tokens };
}

export async function refreshAccessToken(refreshToken) {
  const payload = verifyRefreshToken(refreshToken);
  const user = await prisma.user.findUnique({ where: { id: payload.sub } });

  if (!user || user.status !== 'active') {
    throw new UnauthorizedError('Session invalide');
  }

  const storedTokens = await prisma.refreshToken.findMany({
    where: {
      userId: user.id,
      revokedAt: null,
      expiresAt: { gt: new Date() }
    }
  });

  const matchingToken = await Promise.any(
    storedTokens.map(async (storedToken) => {
      const matches = await compareSecret(refreshToken, storedToken.tokenHash);
      if (!matches) {
        throw new Error('Token mismatch');
      }
      return storedToken;
    })
  ).catch(() => null);

  if (!matchingToken) {
    throw new UnauthorizedError('Refresh token invalide');
  }

  return {
    user: serializeUser(user),
    accessToken: signAccessToken(user)
  };
}
