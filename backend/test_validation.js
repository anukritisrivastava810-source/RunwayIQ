import companyService from './src/services/company.service.js';
import prisma from './src/config/prisma.js';

// Mock Prisma
prisma.company.findFirst = async () => null; // No duplicate name
prisma.company.create = async (args) => {
  return { id: "test-id", ...args.data };
};

async function run() {
  try {
    const payload = {
      name: 'Test Company ' + Date.now(),
      foundedAt: '2026-07-30T19:35:48.219',
      stage: 'SEED'
    };
    
    console.log("Sending payload to service");
    await companyService.createCompany(payload);
  } catch (err) {
    console.error("Error from createCompany:", err.message);
  }
}

run();
