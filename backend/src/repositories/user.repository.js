import prisma from '../config/prisma.js';

export class UserRepository {
  async create(data) {
    return await prisma.user.create({ data });
  }

  async findByEmail(email) {
    return await prisma.user.findUnique({ where: { email } });
  }

  async findById(id) {
    return await prisma.user.findUnique({ where: { id } });
  }
}
