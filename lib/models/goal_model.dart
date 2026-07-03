class GoalModel {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final double? monthlyContribution;
  final DateTime? deadline;
  final DateTime createdAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.monthlyContribution,
    this.deadline,
    required this.createdAt,
  });

  double get progressPercentage => (currentAmount / targetAmount).clamp(0, 1);

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      monthlyContribution: map['monthly_contribution'] != null
          ? (map['monthly_contribution'] as num).toDouble()
          : null,
      deadline:
      map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'monthly_contribution': monthlyContribution,
      'deadline': deadline?.toIso8601String(),
    };
  }
}