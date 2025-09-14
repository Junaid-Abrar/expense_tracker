import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safar/core/constants/app_colors.dart';
import '../../../core/utils/translation_helper.dart';
import '../../../providers/auth_provider.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  static const String supportEmail = 'junaidabrar@gmail.com';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openEmailApp(String feedbackType) async {
    final subject = Uri.encodeComponent('Safar - $feedbackType');
    final body = Uri.encodeComponent('''
Hello Junaid,

I would like to share the following $feedbackType:

[Please write your message here]

---
App Version: 1.0.0
Device: ${Theme.of(context).platform.name}
''');
    
    final emailUri = Uri.parse('mailto:$supportEmail?subject=$subject&body=$body');
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showFallbackDialog(feedbackType);
      }
    } catch (e) {
      _showFallbackDialog(feedbackType);
    }
  }

  void _showFallbackDialog(String feedbackType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.email_outlined, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            const Text('Email Not Available', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please send your feedback manually to:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                supportEmail,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
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
                              TranslationHelper.getText('send_feedback', language),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              TranslationHelper.getText('share_thoughts', language),
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
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildWelcomeCard(language),
                          const SizedBox(height: 24),
                          _buildFeedbackOptions(language),
                          const SizedBox(height: 24),
                          _buildContactInfo(language),
                        ],
                      ),
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

  Widget _buildWelcomeCard(String language) {
    return Container(
      width: double.infinity,
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
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.feedback_outlined, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'We\'d Love to Hear From You!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your feedback helps us improve the app and provide better features for managing your expenses.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              height: 1.5,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackOptions(String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Feedback Type',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeedbackOptionCard(
          icon: Icons.bug_report_outlined,
          title: 'Report a Bug',
          subtitle: 'Found something that\'s not working?',
          color: Colors.red,
          onTap: () => _openEmailApp('Bug Report'),
        ),
        const SizedBox(height: 12),
        _buildFeedbackOptionCard(
          icon: Icons.lightbulb_outline,
          title: 'Suggest a Feature',
          subtitle: 'Have an idea for improvement?',
          color: Colors.amber,
          onTap: () => _openEmailApp('Feature Request'),
        ),
        const SizedBox(height: 12),
        _buildFeedbackOptionCard(
          icon: Icons.favorite_outline,
          title: 'General Feedback',
          subtitle: 'Share your thoughts about the app',
          color: Colors.pink,
          onTap: () => _openEmailApp('General Feedback'),
        ),
        const SizedBox(height: 12),
        _buildFeedbackOptionCard(
          icon: Icons.help_outline,
          title: 'Need Help?',
          subtitle: 'Get support with using the app',
          color: Colors.blue,
          onTap: () => _openEmailApp('Support Request'),
        ),
      ],
    );
  }

  Widget _buildFeedbackOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(String language) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.contact_mail_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Contact Information',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.email_outlined,
            label: 'Email',
            value: supportEmail,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.access_time,
            label: 'Response Time',
            value: 'Usually within 24 hours',
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tapping any option above will open your email app with a pre-filled message.',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
