import '../core/constants/app_constants.dart';
import '../models/transaction_model.dart';

class SmsParserService {
  static TransactionModel? parse(String sms, String userId) {
    sms = sms.trim();

    if (_isMtnMomo(sms)) return _parseMtn(sms, userId);
    if (_isVodafone(sms)) return _parseVodafone(sms, userId);
    if (_isAirtelTigo(sms)) return _parseAirtelTigo(sms, userId);

    return null;
  }

  // ─── MTN MoMo ───────────────────────────────────────────────

  static bool _isMtnMomo(String sms) {
    return sms.contains('MoMo') ||
        sms.contains('mtnmymomo') ||
        sms.contains('Financial Transaction Id');
  }

  static TransactionModel? _parseMtn(String sms, String userId) {
    try {
      double? amount;
      String? senderOrRecipient;
      String type = AppConstants.debit;
      DateTime timestamp = DateTime.now();

      // Debit: "Your payment of GHS X.XX to RECIPIENT has been completed at DATETIME"
      final debitMatch = RegExp(
        r'Your payment of GHS ([\d.]+) to (.+?) has been completed at ([\d-]+ [\d:]+)',
      ).firstMatch(sms);

      if (debitMatch != null) {
        amount = double.parse(debitMatch.group(1)!);
        senderOrRecipient = debitMatch.group(2)!.trim();
        timestamp = DateTime.parse(debitMatch.group(3)!);
        type = AppConstants.debit;
      }

      // Credit: "You have received GHS X.XX from SENDER"
      final creditMatch = RegExp(
        r'You have received GHS ([\d.]+) from (.+?) on',
      ).firstMatch(sms);

      if (creditMatch != null) {
        amount = double.parse(creditMatch.group(1)!);
        senderOrRecipient = creditMatch.group(2)!.trim();
        type = AppConstants.credit;
      }

      // Withdrawal: "You have withdrawn GHS X.XX"
      final withdrawMatch = RegExp(
        r'You have withdrawn GHS ([\d.]+)',
      ).firstMatch(sms);

      if (withdrawMatch != null) {
        amount = double.parse(withdrawMatch.group(1)!);
        senderOrRecipient = 'Cash Withdrawal';
        type = AppConstants.debit;
      }

      if (amount == null) return null;

      return TransactionModel(
        id: '',
        userId: userId,
        amount: amount,
        type: type,
        senderOrRecipient: senderOrRecipient,
        category: _categorize(senderOrRecipient ?? '', type),
        rawSms: sms,
        timestamp: timestamp,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  // ─── Vodafone / Telecel ──────────────────────────────────────

  static bool _isVodafone(String sms) {
    return sms.contains('Vodafone Cash') ||
        sms.contains('VodaCash') ||
        sms.contains('Telecel Cash') ||
        sms.contains('Telecel') ||
        sms.contains('vodafone');
  }

  static TransactionModel? _parseVodafone(String sms, String userId) {
    try {
      double? amount;
      String? senderOrRecipient;
      String type = AppConstants.debit;
      DateTime timestamp = DateTime.now();

      // Telecel withdrawal: "Confirmed. You have withdrawn GHS50.00 from G74131 - AGENT NAME on 2026-07-03 at 16:39:01"
      final telecelWithdrawMatch = RegExp(
        r'You have withdrawn GHS([\d.]+) from [\w]+ - (.+?)\s+on ([\d-]+) at ([\d:]+)',
      ).firstMatch(sms);

      if (telecelWithdrawMatch != null) {
        amount = double.parse(telecelWithdrawMatch.group(1)!);
        senderOrRecipient = telecelWithdrawMatch.group(2)!.trim();
        final dateStr =
            '${telecelWithdrawMatch.group(3)!} ${telecelWithdrawMatch.group(4)!}';
        timestamp = DateTime.parse(dateStr);
        type = AppConstants.debit;
      }

      // Telecel debit: "Confirmed. GHS10.00 sent to 0596239370 EUGENE on MTN MOBILE MONEY on 2026-07-02 at 15:20:26"
      final telecelDebitMatch = RegExp(
        r'Confirmed\.\s*GHS([\d.]+)\s*sent to\s*[\d]+\s*(.+?)\s*on\s*.+?\s*on\s*([\d-]+)\s*at\s*([\d:]+)',
      ).firstMatch(sms);

      if (telecelDebitMatch != null) {
        amount = double.parse(telecelDebitMatch.group(1)!);
        senderOrRecipient = telecelDebitMatch.group(2)!.trim();
        final dateStr =
            '${telecelDebitMatch.group(3)!} ${telecelDebitMatch.group(4)!}';
        timestamp = DateTime.parse(dateStr);
        type = AppConstants.debit;
      }

      // Telecel credit: "You have received GHS X.XX from SENDER on Telecel Cash"
      final telecelCreditMatch = RegExp(
        r'You have received GHS([\d.]+) from (.+?) on',
      ).firstMatch(sms);

      if (telecelCreditMatch != null) {
        amount = double.parse(telecelCreditMatch.group(1)!);
        senderOrRecipient = telecelCreditMatch.group(2)!.trim();
        type = AppConstants.credit;
      }

      // Old Vodafone debit
      final vodaDebitMatch = RegExp(
        r'GHS ([\d.]+) has been deducted from your Vodafone Cash.*?to (.+?)\.',
      ).firstMatch(sms);

      if (vodaDebitMatch != null) {
        amount = double.parse(vodaDebitMatch.group(1)!);
        senderOrRecipient = vodaDebitMatch.group(2)!.trim();
        type = AppConstants.debit;
      }

      // Old Vodafone credit
      final vodaCreditMatch = RegExp(
        r'You have received GHS ([\d.]+) on your Vodafone Cash from (.+?)\.',
      ).firstMatch(sms);

      if (vodaCreditMatch != null) {
        amount = double.parse(vodaCreditMatch.group(1)!);
        senderOrRecipient = vodaCreditMatch.group(2)!.trim();
        type = AppConstants.credit;
      }

      if (amount == null) return null;

      return TransactionModel(
        id: '',
        userId: userId,
        amount: amount,
        type: type,
        senderOrRecipient: senderOrRecipient,
        category: _categorize(senderOrRecipient ?? '', type),
        rawSms: sms,
        timestamp: timestamp,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  // ─── AirtelTigo Money ───────────────────────────────────────

  static bool _isAirtelTigo(String sms) {
    return sms.contains('AirtelTigo') ||
        sms.contains('Airtel Money') ||
        sms.contains('Tigo Cash');
  }

  static TransactionModel? _parseAirtelTigo(String sms, String userId) {
    try {
      double? amount;
      String? senderOrRecipient;
      String type = AppConstants.debit;
      DateTime timestamp = DateTime.now();

      // Debit
      final debitMatch = RegExp(
        r'GHS([\d.]+) has been sent to (.+?) successfully',
      ).firstMatch(sms);

      if (debitMatch != null) {
        amount = double.parse(debitMatch.group(1)!);
        senderOrRecipient = debitMatch.group(2)!.trim();
        type = AppConstants.debit;
      }

      // Credit
      final creditMatch = RegExp(
        r'You have received GHS([\d.]+) from (.+?)\.',
      ).firstMatch(sms);

      if (creditMatch != null) {
        amount = double.parse(creditMatch.group(1)!);
        senderOrRecipient = creditMatch.group(2)!.trim();
        type = AppConstants.credit;
      }

      if (amount == null) return null;

      return TransactionModel(
        id: '',
        userId: userId,
        amount: amount,
        type: type,
        senderOrRecipient: senderOrRecipient,
        category: _categorize(senderOrRecipient ?? '', type),
        rawSms: sms,
        timestamp: timestamp,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  // ─── Auto Categorization ────────────────────────────────────

  static String _categorize(String recipient, String type) {
    final r = recipient.toUpperCase();

    if (r.contains('AIRTIME') || r.contains('BUNDLE') || r.contains('DATA')) {
      return 'Airtime';
    }
    if (r.contains('ELECTRICITY') ||
        r.contains('ECG') ||
        r.contains('WATER') ||
        r.contains('GWCL') ||
        r.contains('UTILITY') ||
        r.contains('DSTV') ||
        r.contains('GOTV')) {
      return 'Utilities';
    }
    if (r.contains('UBER') ||
        r.contains('BOLT') ||
        r.contains('YANGO') ||
        r.contains('TAXI') ||
        r.contains('BUS')) {
      return 'Transport';
    }
    if (r.contains('SHOPRITE') ||
        r.contains('MELCOM') ||
        r.contains('GAME') ||
        r.contains('PALACE') ||
        r.contains('SHOP') ||
        r.contains('STORE') ||
        r.contains('MARKET')) {
      return 'Shopping';
    }
    if (r.contains('KFC') ||
        r.contains('PIZZA') ||
        r.contains('RESTAURANT') ||
        r.contains('FOOD') ||
        r.contains('CHOP') ||
        r.contains('EAT')) {
      return 'Food';
    }
    if (r.contains('CASH WITHDRAWAL') ||
        r.contains('WITHDRAW') ||
        r.contains('VENTURES') ||
        r.contains('AGENT')) {
      return 'Cash';
    }

    if (type == AppConstants.credit) return 'Transfer';
    if (type == AppConstants.debit) return 'Transfer';

    return 'Other';
  }
}