export function serializeUser(user) {
  if (!user) {
    return null;
  }

  const {
    passwordHash,
    pinHash,
    refreshTokens,
    otpCodes,
    ...safeUser
  } = user;

  return safeUser;
}
