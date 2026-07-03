class AppConstants {
  //Supabase
  static const String supabaseUrl = 'https://fzbcguikmjjkbuwuwsjk.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6YmNndWlrbWpqa2J1d3V3c2prIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI5Mzc5MzYsImV4cCI6MjA5ODUxMzkzNn0.cqGif7QhFyfnYmWdw1P4qO-jdF66LvLmHXji14NTfgc';

  //Transaction Categories
  static const List<String> categories = [
    'Food',
    'Transport',
    'Airtime',
    'Shopping',
    'Transfer',
    'Cash',
    'Other',
  ];

  //Budget periods
  static const String monthly = 'monthly';
  static const String weekly = 'weekly';

  //Transaction types
  static const String debit = 'debit';
  static const String credit = 'credit';

}