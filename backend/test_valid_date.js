import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function run() {
  try {
    await prisma.company.create({
      data: {
        name: 'Test Valid Date',
        foundedAt: new Date("2026-07-30T19:35:48.219"),
      }
    });
  } catch (err) {
    console.log("Error when passing Valid Date to Prisma:");
    console.log(err.message);
  } finally {
    await prisma.$disconnect();
  }
}

run();
