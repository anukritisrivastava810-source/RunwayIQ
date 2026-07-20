import prisma from '../config/prisma.js';

export class FundingRepository {
  async create(data) {
    return await prisma.funding.create({ data });
  }

  async findById(id) {
    return await prisma.funding.findUnique({ where: { id } });
  }

  async findAll(skip, take) {
    return await prisma.funding.findMany({ skip, take });
  }

  async update(id, data) {
    return await prisma.funding.update({
      where: { id },
      data,
    });
  }

  async delete(id) {
    return await prisma.funding.delete({ where: { id } });
  }

  async findByCompany(companyId) {
    return await prisma.funding.findMany({ where: { companyId } });
  }
}
