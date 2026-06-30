export function ok(res, { status = 200, message = 'Operation effectuee', data = {}, meta = {} } = {}) {
  return res.status(status).json({
    success: true,
    message,
    ...data,
    ...meta
  });
}

export function fail(
  res,
  { status = 500, message = 'Erreur serveur', code = 'INTERNAL_ERROR', details = [] } = {}
) {
  return res.status(status).json({
    success: false,
    message,
    error: {
      code,
      details
    }
  });
}
