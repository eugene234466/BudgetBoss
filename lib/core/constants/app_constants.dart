class AppConstants {
  // Supabase - replace with your own project credentials
  static const String supabaseUrl = 'YOUR_PROJECT_URL';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';

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
