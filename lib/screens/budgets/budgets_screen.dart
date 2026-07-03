import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/supabase_service.dart';
import '../../models/budget_model.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  List<BudgetModel> _budgets = [];
  Map<String, double> _spendingByCategory = {};
  bool _isLoading = true;

  final _currencyFormat =
  NumberFormat.currency(locale: 'en_GH', symbol: 'GHS ');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final budgets = await SupabaseService.getBudgets();
      final spending = await SupabaseService.getSpendingByCategory();
      if (mounted) {
        setState(() {
          _budgets = budgets;
          _spendingByCategory = spending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddBudgetSheet() {
    String selectedCategory = 'overall';
    String selectedPeriod = AppConstants.monthly;
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Budget',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Category dropdown
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: AppTheme.cardColor,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['overall', ...AppConstants.categories]
                    .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c == 'overall' ? 'Overall (All Spending)' : c,
                    style:
                    const TextStyle(color: AppTheme.textPrimary),
                  ),
                ))
                    .toList(),
                onChanged: (val) =>
                    setSheetState(() => selectedCategory = val!),
              ),
              const SizedBox(height: 16),
              // Amount field
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limit Amount (GHS)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              // Period dropdown
              DropdownButtonFormField<String>(
                value: selectedPeriod,
                dropdownColor: AppTheme.cardColor,
                decoration: const InputDecoration(labelText: 'Period'),
                items: [
                  DropdownMenuItem(
                    value: AppConstants.monthly,
                    child: const Text('Monthly',
                        style: TextStyle(color: AppTheme.textPrimary)),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.weekly,
                    child: const Text('Weekly',
                        style: TextStyle(color: AppTheme.textPrimary)),
                  ),
                ],
                onChanged: (val) =>
                    setSheetState(() => selectedPeriod = val!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) return;

                  final budget = BudgetModel(
                    id: '',
                    userId: SupabaseService.currentUserId!,
                    category: selectedCategory,
                    limitAmount: amount,
                    period: selectedPeriod,
                    createdAt: DateTime.now(),
                  );

                  await SupabaseService.upsertBudget(budget);
                  if (context.mounted) Navigator.pop(context);
                  await _loadData();
                },
                child: const Text('Save Budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: _budgets.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _budgets.length,
          itemBuilder: (context, index) =>
              _buildBudgetCard(_budgets[index]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBudgetSheet,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildBudgetCard(BudgetModel budget) {
    final spent = budget.category == 'overall'
        ? _spendingByCategory.values.fold<double>(0, (a, b) => a + b)
        : (_spendingByCategory[budget.category] ?? 0);
    final progress = (spent / budget.limitAmount).clamp(0.0, 1.0);
    final isOverBudget = spent >= budget.limitAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isOverBudget
            ? Border.all(color: AppTheme.error.withOpacity(0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                budget.category == 'overall'
                    ? 'Overall Budget'
                    : budget.category,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  Text(
                    budget.period == 'monthly' ? 'Monthly' : 'Weekly',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      await SupabaseService.deleteBudget(budget.id);
                      await _loadData();
                    },
                    child: const Icon(Icons.delete_outline,
                        color: AppTheme.error, size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? AppTheme.error : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currencyFormat.format(spent)} spent',
                style: TextStyle(
                  color: isOverBudget ? AppTheme.error : AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                'of ${_currencyFormat.format(budget.limitAmount)}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
          if (isOverBudget) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppTheme.error, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Over budget by ${_currencyFormat.format(spent - budget.limitAmount)}',
                  style: const TextStyle(color: AppTheme.error, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 48, color: AppTheme.textSecondary),
              SizedBox(height: 12),
              Text(
                'No budgets yet.\nTap + to set a budget.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}