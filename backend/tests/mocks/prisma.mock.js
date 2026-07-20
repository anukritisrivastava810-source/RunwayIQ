import { jest } from '@jest/globals';
import { mockDeep } from 'jest-mock-extended';
import prisma from '../../src/config/prisma.js';

jest.mock('../../src/config/prisma.js', () => ({
  __esModule: true,
  default: mockDeep(),
}));

export const prismaMock = prisma;
