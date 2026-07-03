import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {},
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showBudgetWarning({
    required String category,
    required double spent,
    required double limit,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'budget_alerts',
        'Budget Alerts',
        channelDescription: 'Alerts when you approach or exceed your budget',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    final percent = (spent / limit * 100).toStringAsFixed(0);
    final isOver = spent >= limit;

    await _plugin.show(
      category.hashCode,
      isOver ? '🚨 Budget Exceeded' : '⚠️ Budget Warning',
      isOver
          ? '$category budget exceeded! Spent GHS ${spent.toStringAsFixed(2)} of GHS ${limit.toStringAsFixed(2)}'
          : '$category at $percent% of budget. GHS ${spent.toStringAsFixed(2)} of GHS ${limit.toStringAsFixed(2)} used.',
      details,
    );
  }
}