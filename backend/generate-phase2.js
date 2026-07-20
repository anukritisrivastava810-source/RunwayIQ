import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const SRC_DIR = path.join(__dirname, 'src');

const DIRS = [
  'config',
  'middleware',
  'repositories',
  'services',
  'validations',
  'utils'
];

const ENTITIES = [
  'company',
  'employee',
  'expense',
  'funding',
  'investor',
  'treasury',
  'department',
  'scenario'
];

const filesToCreate = [];

DIRS.forEach(dir => {
  const dirPath = path.join(SRC_DIR, dir);
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
});

filesToCreate.push({
  path: 'config/prisma.js',
  content: "import { PrismaClient } from '@prisma/client';\n\nconst prisma = new PrismaClient();\n\nexport default prisma;\n"
});

filesToCreate.push({
  path: 'config/env.js',
  content: "import dotenv from 'dotenv';\n\ndotenv.config();\n\nexport const env = {\n  port: process.env.PORT || 3000,\n  nodeEnv: process.env.NODE_ENV || 'development',\n};\n"
});

filesToCreate.push({
  path: 'config/constants.js',
  content: "export const CONSTANTS = {\n  DEFAULT_CURRENCY: 'USD',\n  PAGINATION: {\n    DEFAULT_PAGE: 1,\n    DEFAULT_LIMIT: 10,\n  },\n};\n"
});

filesToCreate.push({
  path: 'middleware/errorHandler.js',
  content: "import { ApiError } from '../utils/ApiError.js';\nimport { logger } from '../utils/logger.js';\n\nexport const errorHandler = (err, req, res, next) => {\n  logger.error(err);\n\n  if (err instanceof ApiError) {\n    return res.status(err.statusCode).json({\n      success: false,\n      message: err.message,\n      errors: err.errors,\n    });\n  }\n\n  return res.status(500).json({\n    success: false,\n    message: 'Internal Server Error',\n  });\n};\n"
});

filesToCreate.push({
  path: 'middleware/notFound.js',
  content: "export const notFound = (req, res, next) => {\n  res.status(404).json({\n    success: false,\n    message: 'Resource not found - ' + req.originalUrl,\n  });\n};\n"
});

filesToCreate.push({
  path: 'middleware/validateRequest.js',
  content: "import { ApiError } from '../utils/ApiError.js';\n\nexport const validateRequest = (schema) => {\n  return (req, res, next) => {\n    try {\n      schema.parse(req.body);\n      next();\n    } catch (error) {\n      next(new ApiError(400, 'Validation Error', error.errors));\n    }\n  };\n};\n"
});

filesToCreate.push({
  path: 'middleware/asyncHandler.js',
  content: "export const asyncHandler = (fn) => (req, res, next) => {\n  Promise.resolve(fn(req, res, next)).catch(next);\n};\n"
});

ENTITIES.forEach(entity => {
  const modelName = entity.charAt(0).toUpperCase() + entity.slice(1);
  filesToCreate.push({
    path: "repositories/" + entity + ".repository.js",
    content: "import prisma from '../config/prisma.js';\n\nexport class " + modelName + "Repository {\n  async create(data) {\n    return await prisma." + entity + ".create({ data });\n  }\n\n  async findById(id) {\n    return await prisma." + entity + ".findUnique({ where: { id } });\n  }\n\n  async findAll(skip, take) {\n    return await prisma." + entity + ".findMany({ skip, take });\n  }\n\n  async update(id, data) {\n    return await prisma." + entity + ".update({\n      where: { id },\n      data,\n    });\n  }\n\n  async delete(id) {\n    return await prisma." + entity + ".delete({ where: { id } });\n  }\n\n  async findByCompany(companyId) {\n    return await prisma." + entity + ".findMany({ where: { companyId } });\n  }\n}\n"
  });
});

ENTITIES.forEach(entity => {
  const modelName = entity.charAt(0).toUpperCase() + entity.slice(1);
  filesToCreate.push({
    path: "services/" + entity + ".service.js",
    content: "import { " + modelName + "Repository } from '../repositories/" + entity + ".repository.js';\n\nconst repository = new " + modelName + "Repository();\n\nexport class " + modelName + "Service {\n  async create" + modelName + "(data) {\n    // TODO: Add business logic here\n    return await repository.create(data);\n  }\n\n  async get" + modelName + "ById(id) {\n    return await repository.findById(id);\n  }\n\n  async getAll" + modelName + "s(skip, take) {\n    return await repository.findAll(skip, take);\n  }\n\n  async update" + modelName + "(id, data) {\n    return await repository.update(id, data);\n  }\n\n  async delete" + modelName + "(id) {\n    return await repository.delete(id);\n  }\n\n  async getByCompany(companyId) {\n    return await repository.findByCompany(companyId);\n  }\n}\n"
  });
});

filesToCreate.push({
  path: 'services/dashboard.service.js',
  content: "export class DashboardService {\n  async getDashboard(companyId) {\n    // TODO: implement\n    return {};\n  }\n\n  async getBurnRate(companyId) {\n    // TODO: implement\n    return 0;\n  }\n\n  async getRunway(companyId) {\n    // TODO: implement\n    return 0;\n  }\n\n  async getFundingSummary(companyId) {\n    // TODO: implement\n    return {};\n  }\n}\n"
});

ENTITIES.forEach(entity => {
  filesToCreate.push({
    path: "validations/" + entity + ".validation.js",
    content: "import { z } from 'zod';\n\nexport const create" + entity.charAt(0).toUpperCase() + entity.slice(1) + "Schema = z.object({\n  // TODO: Add full validation fields\n  companyId: z.string().uuid().optional(),\n});\n"
  });
});

filesToCreate.push({
  path: 'utils/ApiResponse.js',
  content: "export class ApiResponse {\n  constructor(statusCode, data, message = 'Success') {\n    this.statusCode = statusCode;\n    this.data = data;\n    this.message = message;\n    this.success = statusCode < 400;\n  }\n}\n"
});

filesToCreate.push({
  path: 'utils/ApiError.js',
  content: "export class ApiError extends Error {\n  constructor(statusCode, message = 'Something went wrong', errors = [], stack = '') {\n    super(message);\n    this.statusCode = statusCode;\n    this.data = null;\n    this.message = message;\n    this.success = false;\n    this.errors = errors;\n\n    if (stack) {\n      this.stack = stack;\n    } else {\n      Error.captureStackTrace(this, this.constructor);\n    }\n  }\n}\n"
});

filesToCreate.push({
  path: 'utils/logger.js',
  content: "export const logger = {\n  info: (msg) => console.log('[INFO]: ' + msg),\n  error: (msg) => console.error('[ERROR]:', msg),\n  warn: (msg) => console.warn('[WARN]: ' + msg),\n};\n"
});

filesToCreate.push({
  path: 'utils/pagination.js',
  content: "export const getPaginationOptions = (page = 1, limit = 10) => {\n  const skip = (page - 1) * limit;\n  return { skip, take: limit };\n};\n"
});

filesToCreate.push({
  path: 'utils/validators.js',
  content: "export const isValidUUID = (uuid) => {\n  const regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;\n  return regex.test(uuid);\n};\n"
});

filesToCreate.push({
  path: 'utils/helpers.js',
  content: "export const formatCurrency = (amount, currency = 'USD') => {\n  return new Intl.NumberFormat('en-US', {\n    style: 'currency',\n    currency,\n  }).format(amount);\n};\n"
});

filesToCreate.push({
  path: 'app.js',
  content: "import express from 'express';\nimport cors from 'cors';\nimport { errorHandler } from './middleware/errorHandler.js';\nimport { notFound } from './middleware/notFound.js';\n\nconst app = express();\n\napp.use(cors());\napp.use(express.json());\n\napp.get('/health', (req, res) => {\n  res.status(200).json({\n    status: 'OK',\n    service: 'RunwayIQ Backend',\n  });\n});\n\n// TODO: Add API routes here\n\napp.use(notFound);\napp.use(errorHandler);\n\nexport default app;\n"
});

filesToCreate.push({
  path: 'server.js',
  content: "import app from './app.js';\nimport { env } from './config/env.js';\nimport { logger } from './utils/logger.js';\nimport prisma from './config/prisma.js';\n\nconst PORT = env.port;\n\nconst server = app.listen(PORT, () => {\n  logger.info('Server is running on port ' + PORT);\n});\n\nconst gracefulShutdown = async () => {\n  logger.info('Shutting down gracefully...');\n  await prisma.$disconnect();\n  server.close(() => {\n    logger.info('Server closed.');\n    process.exit(0);\n  });\n};\n\nprocess.on('SIGTERM', gracefulShutdown);\nprocess.on('SIGINT', gracefulShutdown);\n"
});

filesToCreate.forEach(file => {
  const fullPath = path.join(SRC_DIR, file.path);
  const dir = path.dirname(fullPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(fullPath, file.content, 'utf-8');
});

console.log('Successfully generated all Phase 2 files.');
