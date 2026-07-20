import prisma from '../config/prisma.js';

export class ExpenseRepository {
  async create(data) {
    return await prisma.expense.create({ data });
  }

  async findById(id) {
    return await prisma.expense.findUnique({ where: { id } });
  }

  async findAll(skip, take) {
    return await prisma.expense.findMany({ skip, take });
  }

  async update(id, data) {
    return await prisma.expense.update({
      where: { id },
      data,
    });
  }

  async delete(id) {
    return await prisma.expense.delete({ where: { id } });
  }

  async findByCompany(companyId) {
    return await prisma.expense.findMany({ where: { companyId } });
  }
}
