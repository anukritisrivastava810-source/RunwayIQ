import { ExpenseRepository } from '../repositories/expense.repository.js';

const repository = new ExpenseRepository();

export class ExpenseService {
  async createExpense(data) {
    // TODO: Add business logic here
    return await repository.create(data);
  }

  async getExpenseById(id) {
    return await repository.findById(id);
  }

  async getAllExpenses(skip, take) {
    return await repository.findAll(skip, take);
  }

  async updateExpense(id, data) {
    return await repository.update(id, data);
  }

  async deleteExpense(id) {
    return await repository.delete(id);
  }

  async getByCompany(companyId) {
    return await repository.findByCompany(companyId);
  }
}
