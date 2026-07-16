class AppConstants {
  // Supabase - replace with your own project credentials
  static const String supabaseUrl = 'https://rgrolsukptrkdrguthkp.supabase.co/rest/v1/';
  static const String supabaseAnonKey = 'sb_publishable_F8k4kBh2KrQVmyj9BjrTQw_uWUG0TDm';

  // Transaction categories
  static const List<String> categories = [
    'Food',
    'Transport',
    'Utilities',
    'Airtime',
    'Shopping',
    'Transfer',
    'Cash',
    'Other',
  ];

  // Budget periods
  static const String monthly = 'monthly';
  static const String weekly = 'weekly';

  // Transaction types
  static const String debit = 'debit';
  static const String credit = 'credit';
}
