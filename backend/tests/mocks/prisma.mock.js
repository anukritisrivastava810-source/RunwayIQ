import { jest } from '@jest/globals';
import { mockDeep } from 'jest-mock-extended';
import prisma from '../../src/config/prisma.js';

const mock = mockDeep();

const models = [
  'user',
  'company',
  'employee',
  'department',
  'fundingRound',
  'expense',
  'investor',
  'treasuryInvestment',
  'scenario',
  '$queryRaw',
];

for (const model of models) {
  Object.defineProperty(prisma, model, {
    get() {
      return mock[model];
    },
    set(val) {
      mock[model] = val;
    },
    configurable: true,
  });
}

export const prismaMock = mock;
