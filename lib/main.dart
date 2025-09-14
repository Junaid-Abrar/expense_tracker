import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/services/notification_service.dart';
import 'core/services/biometric_service.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/category_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/theme_provider.dart';
import 'firebase_options.dart';
import 'core/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications
  await NotificationService.initialize();
  NotificationService.setupForegroundNotificationHandler();

  runApp(ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App going to background
        BiometricService.onAppBackground();
        break;
      case AppLifecycleState.resumed:
        // App coming to foreground - handled in router redirect
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ExpenseProvider>(
          create: (_) => ExpenseProvider(),
          update: (_, auth, previous) {
            final provider = previous ?? ExpenseProvider();
            // Only clear data when user actually signs out (not on login state changes)
            if (!auth.isAuthenticated && previous != null && auth.status == AuthStatus.unauthenticated) {
              provider.clearData();
            }
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
          create: (_) => CategoryProvider(),
          update: (_, auth, previous) {
            final provider = previous ?? CategoryProvider();
            // Only clear data when user actually signs out (not on login state changes)
            if (!auth.isAuthenticated && previous != null && auth.status == AuthStatus.unauthenticated) {
              provider.clearData();
            }
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, BudgetProvider>(
          create: (_) => BudgetProvider(),
          update: (_, auth, previous) {
            final provider = previous ?? BudgetProvider();
            // Only clear data when user actually signs out (not on login state changes)
            if (!auth.isAuthenticated && previous != null && auth.status == AuthStatus.unauthenticated) {
              provider.clearData();
            }
            return provider;
          },
        ),
      ],
      child: const App(),
    );
  }
}