import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'screens/auth/auth_gate.dart';
import 'core/theme/app_theme.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );

  await NotificationService.init();

  runApp(const BudgetBoss());
}


class BudgetBoss extends StatelessWidget {
  const BudgetBoss({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BudgetBoss',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: AuthGate(),
    );
  }
}
