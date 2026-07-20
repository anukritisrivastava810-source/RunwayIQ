import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import hpp from 'hpp';
import xss from 'xss-clean';
import swaggerUi from 'swagger-ui-express';
import YAML from 'yamljs';
import path from 'path';
import { fileURLToPath } from 'url';

import { errorHandler } from './middleware/errorHandler.js';
import { notFound } from './middleware/notFound.js';
import apiRoutes from './routes/index.js';
import { logger } from './utils/logger.js';
import prisma from './config/prisma.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// Security Middlewares
app.use(helmet()); // Secure HTTP headers
app.use(xss()); // Prevent XSS attacks
app.use(hpp()); // Prevent HTTP Parameter Pollution
app.use(compression()); // Payload compression

// CORS Configuration
const corsOptions = {
  origin: process.env.NODE_ENV === 'production' ? process.env.FRONTEND_URL : '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
};
app.use(cors(corsOptions));

// Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again after 15 minutes'
});
app.use('/api', limiter);

// Request Parsing
app.use(express.json({ limit: '10kb' })); // Body parser, limit payload size

// Request Logging Middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.originalUrl}`);
  next();
});

// Swagger Documentation
try {
  const swaggerDocument = YAML.load(path.join(__dirname, '../docs/swagger.yaml'));
  app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
} catch (err) {
  logger.warn('Swagger documentation not found or failed to load.');
}

// Observability & Health Checks
app.get('/health', (req, res) => res.status(200).json({ status: 'OK' }));
app.get('/health/liveness', (req, res) => res.status(200).json({ status: 'ALIVE' }));
app.get('/health/readiness', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.status(200).json({ status: 'READY', database: 'connected' });
  } catch (error) {
    res.status(503).json({ status: 'UNAVAILABLE', database: 'disconnected' });
  }
});
app.get('/health/system', (req, res) => {
  res.status(200).json({
    memoryUsage: process.memoryUsage(),
    cpuUsage: process.cpuUsage(),
    uptime: process.uptime(),
    nodeVersion: process.version
  });
});

// API Routes
app.use('/api/v1', apiRoutes);

// Error Handling
app.use(notFound);
app.use(errorHandler);

export default app;
