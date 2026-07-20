/**
 * Utility to build Prisma queries for pagination, filtering, sorting, and searching.
 */
export const buildPrismaQuery = (options = {}) => {
  const { filters = {}, search = {}, sort = {}, pagination = {} } = options;
  
  const query = {};

  // Pagination
  if (pagination.page && pagination.limit) {
    query.skip = (Number(pagination.page) - 1) * Number(pagination.limit);
    query.take = Number(pagination.limit);
  }

  // Sorting
  if (sort.field) {
    query.orderBy = {
      [sort.field]: sort.order === 'desc' ? 'desc' : 'asc'
    };
  } else {
    query.orderBy = { createdAt: 'desc' }; // Default sort
  }

  // Filtering & Search
  query.where = { ...filters };

  if (search.field && search.value) {
    query.where[search.field] = {
      contains: search.value,
      mode: 'insensitive'
    };
  }

  return query;
};
