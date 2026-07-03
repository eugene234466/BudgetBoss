import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../models/goal_model.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<GoalModel> _goals = [];
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
      final goals = await SupabaseService.getGoals();
      if (mounted) {
        setState(() {
          _goals = goals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddGoalSheet() {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final contributionController = TextEditingController();
    DateTime? selectedDeadline;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Savings Goal',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (GHS)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contributionController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Contribution (optional)',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                      DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365 * 5)),
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppTheme.primary,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDeadline = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: AppTheme.textSecondary),
                        const SizedBox(width: 12),
                        Text(
                          selectedDeadline == null
                              ? 'Set Deadline (optional)'
                              : DateFormat('MMM d, yyyy')
                              .format(selectedDeadline!),
                          style: TextStyle(
                            color: selectedDeadline == null
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    final target = double.tryParse(targetController.text);
                    if (target == null || target <= 0) return;

                    final contribution =
                    double.tryParse(contributionController.text);

                    final goal = GoalModel(
                      id: '',
                      userId: SupabaseService.currentUserId!,
                      name: nameController.text.trim(),
                      targetAmount: target,
                      currentAmount: 0,
                      monthlyContribution: contribution,
                      deadline: selectedDeadline,
                      createdAt: DateTime.now(),
                    );

                    await SupabaseService.insertGoal(goal);
                    if (context.mounted) Navigator.pop(context);
                    await _loadData();
                  },
                  child: const Text('Save Goal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddFundsDialog(GoalModel goal) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Add Funds',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (GHS)',
            prefixIcon: Icon(Icons.add),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;
              final newAmount = goal.currentAmount + amount;
              await SupabaseService.updateGoalAmount(goal.id, newAmount);
              if (context.mounted) Navigator.pop(context);
              await _loadData();
            },
            child: const Text('Add'),
          ),
        ],
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
        child: _goals.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _goals.length,
          itemBuilder: (context, index) =>
              _buildGoalCard(_goals[index]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalSheet,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    final progress = goal.progressPercentage;
    final isComplete = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isComplete
            ? Border.all(color: AppTheme.primary.withOpacity(0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Row(
                children: [
                  if (isComplete)
                    const Icon(Icons.check_circle,
                        color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showAddFundsDialog(goal),
                    child: const Icon(Icons.add_circle_outline,
                        color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      await SupabaseService.deleteGoal(goal.id);
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
                isComplete ? AppTheme.primary : Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currencyFormat.format(goal.currentAmount),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% of ${_currencyFormat.format(goal.targetAmount)}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
          if (goal.deadline != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Deadline: ${DateFormat('MMM d, yyyy').format(goal.deadline!)}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
          if (goal.monthlyContribution != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.trending_up,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Monthly: ${_currencyFormat.format(goal.monthlyContribution!)}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
          if (isComplete) ...[
            const SizedBox(height: 8),
            const Text(
              '🎉 Goal achieved!',
              style: TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.bold),
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
              Icon(Icons.savings_outlined,
                  size: 48, color: AppTheme.textSecondary),
              SizedBox(height: 12),
              Text(
                'No goals yet.\nTap + to create a savings goal.',
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