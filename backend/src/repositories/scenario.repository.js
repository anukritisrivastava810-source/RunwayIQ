import prisma from '../config/prisma.js';

export class ScenarioRepository {
  async create(data) {
    return await prisma.scenario.create({ data });
  }

  async findById(id) {
    return await prisma.scenario.findUnique({ where: { id } });
  }

  async findAll(skip, take) {
    return await prisma.scenario.findMany({ skip, take });
  }

  async update(id, data) {
    return await prisma.scenario.update({
      where: { id },
      data,
    });
  }

  async delete(id) {
    return await prisma.scenario.delete({ where: { id } });
  }

  async findByCompany(companyId) {
    return await prisma.scenario.findMany({ where: { companyId } });
  }
}
