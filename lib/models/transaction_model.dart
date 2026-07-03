class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type;
  final String? senderOrRecipient;
  final String category;
  final String rawSms;
  final DateTime timestamp;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    this.senderOrRecipient,
    required this.category,
    required this.rawSms,
    required this.timestamp,
    required this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      userId: map['user_id'],
      amount: (map['amount'] as num).toDouble(),
      type: map['type'],
      senderOrRecipient: map['sender_or_recipient'],
      category: map['category'],
      rawSms: map['raw_sms'],
      timestamp: DateTime.parse(map['timestamp']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'amount': amount,
      'type': type,
      'sender_or_recipient': senderOrRecipient,
      'category': category,
      'raw_sms': rawSms,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}