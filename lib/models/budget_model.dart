class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final double limitAmount;
  final String period;
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.limitAmount,
    required this.period,
    required this.createdAt,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'],
      userId: map['user_id'],
      category: map['category'],
      limitAmount: (map['limit_amount'] as num).toDouble(),
      period: map['period'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'category': category,
      'limit_amount': limitAmount,
      'period': period,
    };
  }
}