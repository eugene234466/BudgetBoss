import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'sms_parser_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';
import '../models/transaction_model.dart';

class SmsService {
  static final SmsQuery _query = SmsQuery();

  static Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<List<TransactionModel>> syncMomoSms() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final granted = await requestPermission();
    if (!granted) throw Exception('SMS permission denied');

    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
    );

    final List<TransactionModel> parsed = [];

    for (final message in messages) {
      final body = message.body;
      if (body == null) continue;
      if (!_isMomoSms(body)) continue;

      final transaction = SmsParserService.parse(body, userId);
      if (transaction == null) continue;

      parsed.add(transaction);
    }

    return parsed;
  }

  static Future<int> syncAndSave() async {
    final transactions = await syncMomoSms();
    int saved = 0;

    for (final transaction in transactions) {
      try {
        await SupabaseService.insertTransaction(transaction);
        saved++;
      } catch (e) {
        continue;
      }
    }

    // Check budgets and fire alerts if needed
    await _checkBudgetAlerts();

    return saved;
  }

  static Future<void> _checkBudgetAlerts() async {
    try {
      final budgets = await SupabaseService.getBudgets();
      final spending = await SupabaseService.getSpendingByCategory();

      for (final budget in budgets) {
        final spent = budget.category == 'overall'
            ? spending.values.fold<double>(0, (a, b) => a + b)
            : (spending[budget.category] ?? 0);

        final percent = spent / budget.limitAmount;

        // Fire at 80% and at 100%
        if (percent >= 0.8) {
          await NotificationService.showBudgetWarning(
            category: budget.category == 'overall'
                ? 'Overall'
                : budget.category,
            spent: spent,
            limit: budget.limitAmount,
          );
        }
      }
    } catch (e) {
      // Don't let notification errors break the sync
    }
  }

  static bool _isMomoSms(String body) {
    final lower = body.toLowerCase();
    return lower.contains('momo') ||
        lower.contains('mobile money') ||
        lower.contains('vodafone cash') ||
        lower.contains('vodacash') ||
        lower.contains('telecel cash') ||
        lower.contains('telecel') ||
        lower.contains('airteltigo') ||
        lower.contains('airtel money') ||
        lower.contains('tigo cash') ||
        lower.contains('financial transaction id');
  }
}