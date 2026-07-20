import { jest } from '@jest/globals';
import './mocks/prisma.mock.js';

// Define global jest to avoid missing variable issues
global.jest = jest;

// Set env variables
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_secret';
process.env.PORT = 3000;
