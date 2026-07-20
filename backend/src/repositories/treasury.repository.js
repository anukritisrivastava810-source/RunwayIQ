import prisma from '../config/prisma.js';

export class TreasuryRepository {
  async create(data) {
    return await prisma.treasury.create({ data });
  }

  async findById(id) {
    return await prisma.treasury.findUnique({ where: { id } });
  }

  async findAll(skip, take) {
    return await prisma.treasury.findMany({ skip, take });
  }

  async update(id, data) {
    return await prisma.treasury.update({
      where: { id },
      data,
    });
  }

  async delete(id) {
    return await prisma.treasury.delete({ where: { id } });
  }

  async findByCompany(companyId) {
    return await prisma.treasury.findMany({ where: { companyId } });
  }
}
