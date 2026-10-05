import prisma from '../config/prisma.js';

export class TreasuryRepository {
  async create(data) {
    return await prisma.treasuryInvestment.create({ data });
  }

  async findById(id) {
    return await prisma.treasuryInvestment.findUnique({ where: { id } });
  }

  async findAll(skip, take) {
    return await prisma.treasuryInvestment.findMany({ skip, take });
  }

  async update(id, data) {
    return await prisma.treasuryInvestment.update({
      where: { id },
      data,
    });
  }

  async delete(id) {
    return await prisma.treasuryInvestment.delete({ where: { id } });
  }

  async findByCompany(companyId) {
    return await prisma.treasuryInvestment.findMany({ where: { companyId } });
  }
}
