import prisma from '../config/prisma.js';

export class ExpenseRepository {
  async create(data) {
    return await prisma.expense.create({ data });
  }

  async findById(id) {
    return await prisma.expense.findUnique({
      where: { id },
      include: { department: true },
    });
  }

  async findAll(skip, take) {
    return await prisma.expense.findMany({
      skip,
      take,
      include: { department: true },
    });
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
    return await prisma.expense.findMany({
      where: { companyId },
      include: { department: true },
    });
  }
}
