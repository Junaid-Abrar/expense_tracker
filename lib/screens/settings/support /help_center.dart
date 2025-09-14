import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safar/core/constants/app_colors.dart';
import '../../../core/utils/translation_helper.dart';
import '../../../providers/auth_provider.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _faqs = [
    {
      'icon': Icons.add_circle_outline,
      'color': Colors.green,
      'question': 'How do I add a new expense?',
      'answer': 'Go to the Home screen and tap the "Add Expense" quick action button, or use the floating action button to add a new expense entry. You can categorize it, add notes, and set the date.'
    },
    {
      'icon': Icons.lock_outline,
      'color': Colors.blue,
      'question': 'How do I change my password?',
      'answer': 'Navigate to Settings > Security & Privacy > Change Password. You\'ll need to enter your current password and then set a new one with at least 6 characters.'
    },
    {
      'icon': Icons.support_outlined,
      'color': Colors.orange,
      'question': 'How do I contact support?',
      'answer': 'Use the "Send Feedback" page in Settings > Support & Information to contact our support team directly via email.'
    },
    {
      'icon': Icons.palette_outlined,
      'color': Colors.purple,
      'question': 'How do I change the app theme?',
      'answer': 'Go to Settings > App Preferences > Theme to choose between Light, Dark, or System default theme modes.'
    },
    {
      'icon': Icons.file_download_outlined,
      'color': Colors.indigo,
      'question': 'How do I export my expenses?',
      'answer': 'This feature will be available soon in the Analytics section. You\'ll be able to export your data as CSV or PDF files.'
    },
    {
      'icon': Icons.category_outlined,
      'color': Colors.teal,
      'question': 'How do I manage categories?',
      'answer': 'You can create custom categories when adding expenses, or manage them through the category selection screen. Default categories are provided for common expense types.'
    },
    {
      'icon': Icons.trending_up,
      'color': Colors.red,
      'question': 'How do I set up budgets?',
      'answer': 'Go to the Budget screen from the home quick actions. You can create monthly or yearly budgets for different categories and track your spending against them.'
    },
    {
      'icon': Icons.notifications_outlined,
      'color': Colors.amber,
      'question': 'How do I enable notifications?',
      'answer': 'Go to Settings > Security & Privacy > Push Notifications to enable reminder notifications for expense tracking and budget alerts.'
    },
  ];

  List<Map<String, dynamic>> _filteredFaqs = [];
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _filteredFaqs = List.from(_faqs);
    _searchController.addListener(_filterFaqs);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
  }

  void _filterFaqs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFaqs = _faqs.where((faq) {
        final question = faq['question']!.toLowerCase();
        final answer = faq['answer']!.toLowerCase();
        return question.contains(query) || answer.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final language = authProvider.getPreference<String>('app_language', 'en');
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
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
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              TranslationHelper.getText('help_center', language),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              TranslationHelper.getText('faqs_guides', language),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSearchBar(language),
                        const SizedBox(height: 24),
                        _buildQuickHelpCards(language),
                        const SizedBox(height: 24),
                        _buildFAQList(language),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(String language) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search FAQs...',
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.search, color: AppColors.primary, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildQuickHelpCards(String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Help',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickHelpCard(
                icon: Icons.add,
                title: 'Add Expense',
                subtitle: 'Learn how to track',
                color: Colors.green,
                onTap: () => _showQuickGuide(context, 'Add Expense', 'Tap the "Add Expense" button on the home screen, fill in the amount, select a category, and add any notes.'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickHelpCard(
                icon: Icons.pie_chart,
                title: 'Budgets',
                subtitle: 'Set spending limits',
                color: Colors.blue,
                onTap: () => _showQuickGuide(context, 'Budget Setup', 'Go to the Budget section, tap "Create Budget", select a category, set your limit, and choose the time period.'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickHelpCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQList(String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _filteredFaqs.isEmpty
            ? _buildNoResultsState()
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredFaqs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final faq = _filteredFaqs[index];
                  return _buildFAQCard(faq);
                },
              ),
      ],
    );
  }

  Widget _buildFAQCard(Map<String, dynamic> faq) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: faq['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(faq['icon'], color: faq['color'], size: 20),
          ),
          title: Text(
            faq['question']!,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: faq['color'].withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                faq['answer']!,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showQuickGuide(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.help_outline, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
