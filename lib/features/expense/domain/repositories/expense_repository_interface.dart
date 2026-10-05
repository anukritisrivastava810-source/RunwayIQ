import '../models/expense.dart';

abstract class IExpenseRepository {
  Future<Expense> createExpense(Expense expense);
  Future<List<Expense>> getAllExpenses();
  Future<Expense> getExpenseById(String id);
  Future<List<Expense>> getExpensesByCompany(String companyId);
  Future<Expense> updateExpense(String id, Expense expense);
  Future<void> deleteExpense(String id);
}
