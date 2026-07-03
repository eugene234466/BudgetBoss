import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // ─── Auth ────────────────────────────────────────────────────

  static String? get currentUserId => _client.auth.currentUser?.id;

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ─── Transactions ────────────────────────────────────────────

  static Future<void> insertTransaction(TransactionModel transaction) async {
    await _client.from('transactions').upsert(
      transaction.toMap(),
      onConflict: 'user_id, raw_sms',
      ignoreDuplicates: true,
    );
  }

  static Future<List<TransactionModel>> getTransactions() async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', currentUserId!)
        .order('timestamp', ascending: false);

    return (response as List)
        .map((e) => TransactionModel.fromMap(e))
        .toList();
  }

  static Future<List<TransactionModel>> getTransactionsByCategory(
      String category) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', currentUserId!)
        .eq('category', category)
        .order('timestamp', ascending: false);

    return (response as List)
        .map((e) => TransactionModel.fromMap(e))
        .toList();
  }

  static Future<double> getTotalSpentThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final response = await _client
        .from('transactions')
        .select('amount')
        .eq('user_id', currentUserId!)
        .eq('type', 'debit')
        .gte('timestamp', startOfMonth.toIso8601String());

    final list = response as List;
    return list.fold<double>(0.0, (sum, e) => sum + (e['amount'] as num).toDouble());
  }

  static Future<Map<String, double>> getSpendingByCategory() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final response = await _client
        .from('transactions')
        .select('category, amount')
        .eq('user_id', currentUserId!)
        .eq('type', 'debit')
        .gte('timestamp', startOfMonth.toIso8601String());

    final Map<String, double> result = {};
    for (final row in response as List) {
      final category = row['category'] as String;
      final amount = (row['amount'] as num).toDouble();
      result[category] = (result[category] ?? 0) + amount;
    }
    return result;
  }

  static Future<void> deleteTransaction(String id) async {
    await _client.from('transactions').delete().eq('id', id);
  }

  // ─── Budgets ─────────────────────────────────────────────────

  static Future<void> upsertBudget(BudgetModel budget) async {
    await _client.from('budgets').upsert(
      budget.toMap(),
      onConflict: 'user_id, category',
    );
  }

  static Future<List<BudgetModel>> getBudgets() async {
    final response = await _client
        .from('budgets')
        .select()
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: true);

    return (response as List).map((e) => BudgetModel.fromMap(e)).toList();
  }

  static Future<void> deleteBudget(String id) async {
    await _client.from('budgets').delete().eq('id', id);
  }

  // ─── Goals ───────────────────────────────────────────────────

  static Future<void> insertGoal(GoalModel goal) async {
    await _client.from('goals').insert(goal.toMap());
  }

  static Future<List<GoalModel>> getGoals() async {
    final response = await _client
        .from('goals')
        .select()
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: true);

    return (response as List).map((e) => GoalModel.fromMap(e)).toList();
  }

  static Future<void> updateGoalAmount(String id, double newAmount) async {
    await _client
        .from('goals')
        .update({'current_amount': newAmount}).eq('id', id);
  }

  static Future<void> deleteGoal(String id) async {
    await _client.from('goals').delete().eq('id', id);
  }
}