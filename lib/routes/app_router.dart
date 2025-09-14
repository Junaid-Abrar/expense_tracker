import 'package:safar/screens/categories/add_category_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../core/services/biometric_service.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/biometric_auth_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/expenses/add_expense_screen.dart';
import '../screens/expenses/expense_list_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/budget/add_budget_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../screens/settings/currency_settings_screen.dart';
import '../screens/settings/language_settings_screen.dart';
import '../screens/settings/payment_methods_screen.dart';
import '../screens/settings/transaction_history_screen.dart';
import '../screens/settings/preferences_screen.dart';
import '../screens/settings/support /about.dart';
import '../screens/settings/support /help_center.dart';
import '../screens/settings/support /Send_Feedback.dart';

class AppRouter {
  static bool? _cachedOnboardingStatus;
  
  static GoRouter createRouter(AuthProvider authProvider) {
    // Reset cache when creating a new router to ensure fresh state
    _cachedOnboardingStatus = null;
    return GoRouter(
      initialLocation: '/onboarding',
      redirect: (context, state) async {
        final isAuthenticated = authProvider.isAuthenticated;
        final currentLocation = state.uri.toString();

        print('DEBUG: Router redirect - Location: $currentLocation, Auth: $isAuthenticated');

        // Cache onboarding status to avoid repeated SharedPreferences calls
        if (_cachedOnboardingStatus == null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            _cachedOnboardingStatus = prefs.getBool('onboarding_completed') ?? false; // Default to NOT completed for fresh users
          } catch (e) {
            // If SharedPreferences fails, assume onboarding is NOT completed for safety
            _cachedOnboardingStatus = false;
          }
        }

        final isOnboardingCompleted = _cachedOnboardingStatus ?? false;

        print('DEBUG: Onboarding completed: $isOnboardingCompleted');

        // If onboarding not completed, go to onboarding (unless already there)
        if (!isOnboardingCompleted && currentLocation != '/onboarding') {
          print('DEBUG: Redirecting to onboarding');
          return '/onboarding';
        }

        // If onboarding completed but not authenticated, go to login (unless already there)
        if (isOnboardingCompleted && !isAuthenticated && !currentLocation.startsWith('/auth')) {
          print('DEBUG: Redirecting to login');
          return '/auth/login';
        }

        // If user is authenticated
        if (isAuthenticated) {
          // If accessing auth or onboarding pages when authenticated, redirect to home
          if (currentLocation.startsWith('/auth') || currentLocation == '/onboarding') {
            print('DEBUG: Redirecting authenticated user to home');
            return '/home';
          }
        }

        print('DEBUG: No redirect needed');
        return null; // No redirect needed
      },
      routes: [
        // Onboarding
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),

        // Authentication routes
        GoRoute(
          path: '/auth/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/auth/biometric',
          name: 'biometric-auth',
          builder: (context, state) => const BiometricAuthScreen(),
        ),

        // Main app routes
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),

        // Expense routes
        GoRoute(
          path: '/expenses/add',
          name: 'add-expense',
          builder: (context, state) => const AddExpenseScreen(),
        ),

        GoRoute(
          path: '/expenses/list',
          name: 'expense-list',
          builder: (context, state) => const ExpenseListScreen(),
        ),

        // Analytics
        GoRoute(
          path: '/analytics',
          name: 'analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),

        // Budget routes
        GoRoute(
          path: '/budget',
          name: 'budget',
          builder: (context, state) => const BudgetScreen(),
        ),
        GoRoute(
          path: '/budget/add',
          name: 'add-budget',
          builder: (context, state) => const AddBudgetScreen(),
        ),

        // Category routes
        GoRoute(
          path: '/categories/add',
          name: 'add-category',
          builder: (context, state) => const AddCategoryScreen(),
        ),

        // Settings routes
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/settings/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings/currency',
          name: 'currency-settings',
          builder: (context, state) => const CurrencySettingsScreen(),
        ),
        GoRoute(
          path: '/settings/language',
          name: 'language-settings',
          builder: (context, state) => const LanguageSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/payment-methods',
          name: 'payment-methods',
          builder: (context, state) => const PaymentMethodsScreen(),
        ),
        GoRoute(
          path: '/settings/transaction-history',
          name: 'transaction-history',
          builder: (context, state) => const TransactionHistoryScreen(),
        ),
        GoRoute(
          path: '/settings/preferences',
          name: 'preferences',
          builder: (context, state) => const PreferencesScreen(),
        ),
        // Support routes
        GoRoute(
          path: '/settings/support/about',
          name: 'about',
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(
          path: '/settings/support/help-center',
          name: 'help-center',
          builder: (context, state) => const HelpCenterScreen(),
        ),
        GoRoute(
          path: '/settings/support/send-feedback',
          name: 'send-feedback',
          builder: (context, state) => const SendFeedbackScreen(),
        ),
      ],
    );
  }
  
  // Method to clear the cached onboarding status when onboarding is completed
  static void clearOnboardingCache() {
    _cachedOnboardingStatus = null;
  }
}