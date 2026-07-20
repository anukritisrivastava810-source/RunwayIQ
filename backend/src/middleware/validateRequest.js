import { ApiError } from '../utils/ApiError.js';

export const validateRequest = (schema) => {
  return (req, res, next) => {
    try {
      schema.parse(req.body);
      next();
    } catch (error) {
      next(new ApiError(400, 'Validation Error', error.errors));
    }
  };
};
