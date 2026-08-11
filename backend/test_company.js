import companyRepository from './src/repositories/company.repository.js';
import prisma from './src/config/prisma.js';

// Mock the prisma company create method
prisma.company.create = async (args) => {
  console.log("Mock Prisma received:", args);
  return { id: "test-id", ...args.data };
};

async function run() {
  try {
    const payload = {
      name: 'Test Company ' + Date.now(),
      foundedAt: '2026-07-30T19:35:48.219',
      stage: 'SEED'
    };
    
    console.log("Sending payload:", payload);
    const result = await companyRepository.create(payload);
    
    console.log("\nSuccess:");
    console.log("Result foundedAt is Date object?", result.foundedAt instanceof Date);
    console.log("Result:", result);
  } catch (err) {
    console.error("Error:", err.message);
  }
}

run();
