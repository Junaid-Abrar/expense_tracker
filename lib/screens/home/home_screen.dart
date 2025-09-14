import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/translation_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';
import '../../models/expense_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start animation immediately
    _animationController.forward();
    
    // Load data after the first frame to prevent blocking the UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dataLoaded) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_dataLoaded) return;
    
    try {
      final authProvider = context.read<AuthProvider>();
      
      // Only load data if user is fully authenticated
      if (!authProvider.isAuthenticated) {
        debugPrint('User not authenticated, skipping data load');
        return;
      }
      
      final expenseProvider = context.read<ExpenseProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      final budgetProvider = context.read<BudgetProvider>();
      
      // Load all data concurrently for better performance
      await Future.wait([
        categoryProvider.loadCategories(), // Load categories FIRST
        expenseProvider.loadExpenses(),
        budgetProvider.loadBudgets(),
      ]);
      
      _dataLoaded = true;
    } catch (e) {
      // Handle error silently to prevent UI issues
      debugPrint('Error loading home screen data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, ({String language, bool isAuthenticated})>(
      selector: (context, authProvider) => (
        language: authProvider.getPreference<String>('app_language', 'en'),
        isAuthenticated: authProvider.isAuthenticated,
      ),
      builder: (context, authData, _) {
        final language = authData.language;
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              _dataLoaded = false;
              await _loadData();
            },
            child: CustomScrollView(
              slivers: [
                _buildModernAppBar(language),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildEnhancedFinancialOverview(language),
                          const SizedBox(height: 32),
                          _buildQuickActions(language),
                          const SizedBox(height: 32),
                          _buildRecentTransactions(language),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernAppBar(String language) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
                AppColors.secondary,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                top: 80,
                right: 20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final user = authProvider.userModel;
                          final hour = DateTime.now().hour;
                          String greeting;
                          if (hour < 12) {
                            greeting = TranslationHelper.getText('good_morning', language);
                          } else if (hour < 17) {
                            greeting = TranslationHelper.getText('good_afternoon', language);
                          } else {
                            greeting = TranslationHelper.getText('good_evening', language);
                          }

                          // Use a more robust username display logic
                          String displayName = '';
                          if (user?.displayName != null && user!.displayName!.isNotEmpty) {
                            displayName = user.displayName!.split(' ').first;
                          } else if (authProvider.user?.displayName != null && authProvider.user!.displayName!.isNotEmpty) {
                            displayName = authProvider.user!.displayName!.split(' ').first;
                          } else if (authProvider.user?.email != null) {
                            displayName = authProvider.user!.email!.split('@')[0];
                          } else {
                            displayName = TranslationHelper.getText('user', language);
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final notificationsEnabled = authProvider.userModel?.notificationsEnabled ?? false;
              
              return IconButton(
                icon: Icon(
                  notificationsEnabled ? Icons.notifications : Icons.notifications_off_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () async {
                  final currentValue = authProvider.userModel?.notificationsEnabled ?? false;
                  
                  if (!currentValue) {
                    // Enable notifications
                    await NotificationService.initialize();
                    final hasPermission = await NotificationService.requestPermissions();
                    
                    if (hasPermission) {
                      await authProvider.updateProfile(notificationsEnabled: true);
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(TranslationHelper.getText('notifications_enabled', language)),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      
                      // Send a test notification
                      await NotificationService.showLocalNotification(
                        title: TranslationHelper.getText('notifications_enabled', language),
                        body: TranslationHelper.getText('notification_test_message', language),
                      );
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(TranslationHelper.getText('notification_permission_denied', language)),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } else {
                    // Disable notifications
                    await authProvider.updateProfile(notificationsEnabled: false);
                    await NotificationService.cancelAllNotifications();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(TranslationHelper.getText('notifications_disabled', language)),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
            onSelected: (value) async {
              switch (value) {
                case 'settings':
                  context.push('/settings');
                  break;
                case 'profile':
                  context.push('/settings/profile');
                  break;
                case 'signout':
                  final authProvider = context.read<AuthProvider>();
                  await authProvider.signOut();
                  if (mounted) context.go('/auth/login');
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings),
                    const SizedBox(width: 8),
                    Text(TranslationHelper.getText('settings', language)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(TranslationHelper.getText('profile', language)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      TranslationHelper.getText('sign_out', language),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedFinancialOverview(String language) {
    return Consumer2<ExpenseProvider, AuthProvider>(
      builder: (context, expenseProvider, authProvider, child) {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);

        final monthlyExpenses = expenseProvider.getTotalForPeriod(
          startOfMonth,
          endOfMonth,
          expensesOnly: true,
        );

        final monthlyIncome = expenseProvider.expenses
            .where((e) =>
        e.isIncome &&
            e.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            e.date.isBefore(endOfMonth.add(const Duration(days: 1))))
            .fold(0.0, (sum, e) => sum + e.amount);

        final balance = monthlyIncome - monthlyExpenses;

        String formatAmount(double amount) {
          return authProvider.userModel?.formatCurrency(amount) ??
              '\$${amount.toStringAsFixed(2)}';
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Month indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  TranslationHelper.getText('this_month', language),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Balance section
              Column(
                children: [
                  Text(
                    TranslationHelper.getText('total_balance', language),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatAmount(balance),
                    style: TextStyle(
                      color: balance >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Income and Expenses row
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedOverviewItem(
                      TranslationHelper.getText('income', language),
                      formatAmount(monthlyIncome),
                      Icons.trending_up_rounded,
                      Colors.green,
                      true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEnhancedOverviewItem(
                      TranslationHelper.getText('expenses', language),
                      formatAmount(monthlyExpenses),
                      Icons.trending_down_rounded,
                      Colors.red,
                      false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedOverviewItem(String label, String amount, IconData icon, Color color, bool isIncome) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationHelper.getText('quick_actions', language),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildActionCard(
              TranslationHelper.getText('add_expense', language),
              Icons.remove_circle_outline,
              Colors.red.shade400,
                  () => context.push('/expenses/add'),
            ),
            _buildActionCard(
              TranslationHelper.getText('add_income', language),
              Icons.add_circle_outline,
              Colors.green.shade400,
                  () => context.push('/expenses/add?type=income'),
            ),
            _buildActionCard(
              TranslationHelper.getText('budget', language),
              Icons.pie_chart_outline,
              Colors.blue.shade400,
                  () => context.push('/budget'),
            ),
            _buildActionCard(
              TranslationHelper.getText('analytics', language),
              Icons.analytics_outlined,
              Colors.purple.shade400,
                  () => context.push('/analytics'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                TranslationHelper.getText('recent_transactions', language),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8), // small spacing
            TextButton(
              onPressed: () => context.push('/expenses/list'),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  TranslationHelper.getText('view_all', language),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Consumer3<ExpenseProvider, AuthProvider, CategoryProvider>(
          builder: (context, expenseProvider, authProvider, categoryProvider, child) {
            if (expenseProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final recentExpenses = expenseProvider.recentExpenses;

            if (recentExpenses.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      TranslationHelper.getText('no_transactions_yet', language),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      TranslationHelper.getText('start_tracking_expenses', language),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/expenses/add'),
                      icon: const Icon(Icons.add),
                      label: Text(TranslationHelper.getText('add_transaction', language)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            String formatAmount(double amount) {
              return authProvider.userModel?.formatCurrency(amount) ??
                  '\$${amount.toStringAsFixed(2)}';
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentExpenses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final expense = recentExpenses[index];
                final category = categoryProvider.getCategoryById(expense.categoryId);

                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: expense.isExpense
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        expense.isExpense ? Icons.trending_down : Icons.trending_up,
                        color: expense.isExpense ? Colors.red : Colors.green,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      expense.description?.isNotEmpty == true
                          ? expense.description!
                          : (category?.getLocalizedName(language) ?? TranslationHelper.getText('unknown', language)),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      category?.getLocalizedName(language) ?? TranslationHelper.getText('unknown', language),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${expense.isExpense ? '-' : '+'}${formatAmount(expense.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: expense.isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${expense.date.day}/${expense.date.month}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}