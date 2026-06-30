export function getPagination(query) {
  const page = Math.max(Number(query.page || 1), 1);
  const requestedLimit = Math.max(Number(query.limit || 20), 1);
  const limit = Math.min(requestedLimit, 100);
  const skip = (page - 1) * limit;

  return { page, limit, skip };
}

export function paginationMeta({ page, limit, total }) {
  return {
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit)
    }
  };
}
