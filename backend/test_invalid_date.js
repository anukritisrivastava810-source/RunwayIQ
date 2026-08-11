import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function run() {
  try {
    await prisma.company.create({
      data: {
        name: 'Test Invalid Date',
        foundedAt: new Date("invalid-date-string"),
      }
    });
  } catch (err) {
    console.log("Error when passing Invalid Date to Prisma:");
    console.log(err.message);
  } finally {
    await prisma.$disconnect();
  }
}

run();
