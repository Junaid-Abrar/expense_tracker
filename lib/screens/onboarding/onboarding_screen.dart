import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../../core/constants/app_colors.dart';
import '../../core/utils/translation_helper.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';

class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final List<OnboardingFeature> features;
  final String statistic;
  final String statisticLabel;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.features,
    required this.statistic,
    required this.statisticLabel,
  });
}

class OnboardingFeature {
  final IconData icon;
  final String title;
  final String description;

  OnboardingFeature({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _floatController;
  late List<AnimationController> _fadeControllers;
  late List<Animation<double>> _fadeAnimations;

  late Animation<double> _floatAnimation;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Create fade controllers for each page
    _fadeControllers = List.generate(4, (index) => 
      AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      )
    );

    _fadeAnimations = _fadeControllers.map((controller) => 
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      )
    ).toList();

    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Start animation for first page
    _fadeControllers[0].forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _fadeControllers) {
      controller.dispose();
    }
    _floatController.dispose();
    super.dispose();
  }

  String _getTranslation(String key, String language) {
    try {
      return TranslationHelper.getText(key, language);
    } catch (e) {
      return '';
    }
  }

  List<OnboardingData> _getPages(String language) => [
    // Page 1: Smart Expense Tracking
    OnboardingData(
      title: _getTranslation('onboarding_title_1', language).isNotEmpty
          ? _getTranslation('onboarding_title_1', language)
          : 'Smart Expense',
      subtitle: _getTranslation('onboarding_subtitle_1', language).isNotEmpty
          ? _getTranslation('onboarding_subtitle_1', language)
          : 'Tracking',
      description: _getTranslation('onboarding_desc_1', language).isNotEmpty
          ? _getTranslation('onboarding_desc_1', language)
          : 'Track every expense effortlessly with AI-powered categorization, receipt scanning, and real-time synchronization across all your devices.',
      icon: Icons.account_balance_wallet_outlined,
      gradient: [const Color(0xFF3B82F6), const Color(0xFF1E40AF)],
      statistic: '99.9%',
      statisticLabel: 'Accuracy Rate',
      features: [
        OnboardingFeature(
          icon: Icons.camera_alt_outlined,
          title: 'Receipt Scanning',
          description: 'Scan receipts instantly with OCR technology',
        ),
        OnboardingFeature(
          icon: Icons.auto_awesome,
          title: 'Smart Categories',
          description: 'AI automatically categorizes your expenses',
        ),
        OnboardingFeature(
          icon: Icons.sync,
          title: 'Real-time Sync',
          description: 'Access your data from any device, anywhere',
        ),
      ],
    ),

    // Page 2: Powerful Analytics
    OnboardingData(
      title: _getTranslation('onboarding_title_2', language).isNotEmpty
          ? _getTranslation('onboarding_title_2', language)
          : 'Powerful',
      subtitle: _getTranslation('onboarding_subtitle_2', language).isNotEmpty
          ? _getTranslation('onboarding_subtitle_2', language)
          : 'Analytics',
      description: _getTranslation('onboarding_desc_2', language).isNotEmpty
          ? _getTranslation('onboarding_desc_2', language)
          : 'Gain deep insights into your spending patterns with interactive charts, trend analysis, and personalized recommendations to optimize your budget.',
      icon: Icons.analytics_outlined,
      gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
      statistic: '73%',
      statisticLabel: 'Average Savings',
      features: [
        OnboardingFeature(
          icon: Icons.pie_chart_outline,
          title: 'Visual Reports',
          description: 'Beautiful charts and graphs for clear insights',
        ),
        OnboardingFeature(
          icon: Icons.trending_up,
          title: 'Trend Analysis',
          description: 'Identify spending patterns and habits',
        ),
        OnboardingFeature(
          icon: Icons.lightbulb_outline,
          title: 'Smart Insights',
          description: 'Get personalized financial recommendations',
        ),
      ],
    ),

    // Page 3: Bank-Level Security
    OnboardingData(
      title: _getTranslation('onboarding_title_3', language).isNotEmpty
          ? _getTranslation('onboarding_title_3', language)
          : 'Bank-Level',
      subtitle: _getTranslation('onboarding_subtitle_3', language).isNotEmpty
          ? _getTranslation('onboarding_subtitle_3', language)
          : 'Security',
      description: _getTranslation('onboarding_desc_3', language).isNotEmpty
          ? _getTranslation('onboarding_desc_3', language)
          : 'Your financial data is protected with enterprise-grade encryption, biometric authentication, and SOC 2 compliance standards.',
      icon: Icons.security_outlined,
      gradient: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      statistic: '256-bit',
      statisticLabel: 'Encryption',
      features: [
        OnboardingFeature(
          icon: Icons.fingerprint,
          title: 'Biometric Login',
          description: 'Secure access with fingerprint or face ID',
        ),
        OnboardingFeature(
          icon: Icons.shield_outlined,
          title: 'Data Protection',
          description: 'End-to-end encryption for all your data',
        ),
        OnboardingFeature(
          icon: Icons.verified_outlined,
          title: 'SOC 2 Compliant',
          description: 'Industry-standard security certifications',
        ),
      ],
    ),

    // Page 4: Ready to Start
    OnboardingData(
      title: _getTranslation('onboarding_title_4', language).isNotEmpty
          ? _getTranslation('onboarding_title_4', language)
          : 'Ready to',
      subtitle: _getTranslation('onboarding_subtitle_4', language).isNotEmpty
          ? _getTranslation('onboarding_subtitle_4', language)
          : 'Get Started?',
      description: _getTranslation('onboarding_desc_4', language).isNotEmpty
          ? _getTranslation('onboarding_desc_4', language)
          : 'Join over 2 million users who have transformed their financial management and achieved their savings goals with our comprehensive platform.',
      icon: Icons.rocket_launch_outlined,
      gradient: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      statistic: '2M+',
      statisticLabel: 'Happy Users',
      features: [
        OnboardingFeature(
          icon: Icons.support_agent,
          title: '24/7 Support',
          description: 'Expert help whenever you need it',
        ),
        OnboardingFeature(
          icon: Icons.language,
          title: 'Multi-Language',
          description: 'Available in 12+ languages worldwide',
        ),
        OnboardingFeature(
          icon: Icons.star_outline,
          title: '4.8★ Rating',
          description: 'Trusted by millions of satisfied users',
        ),
      ],
    ),
  ];

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      
      // Clear the router cache to ensure proper navigation
      AppRouter.clearOnboardingCache();

      if (mounted) {
        context.pushReplacement('/auth/login');
      }
    } catch (e) {
      print('Error completing onboarding: $e');
      // Even if there's an error, try to navigate
      if (mounted) {
        context.pushReplacement('/auth/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final language = authProvider.userModel?.locale?.split('_').first ?? 'en';
        final pages = _getPages(language);
        final currentPageData = pages[_currentPage];

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                _buildTopBar(language),

                // Main Content - Fixed Height to Prevent Overflow
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      // Trigger fade animation for the new page
                      _fadeControllers[index].reset();
                      _fadeControllers[index].forward();
                    },
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(pages[index], index);
                    },
                  ),
                ),

                // Bottom Navigation - Fixed Height
                _buildBottomSection(pages.length, language, currentPageData),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(String language) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getPages(language)[_currentPage].gradient,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Safar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),

          // Skip Button
          if (_currentPage < 3)
            TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                _getTranslation('skip', language).isNotEmpty
                    ? _getTranslation('skip', language)
                    : 'Skip',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data, int pageIndex) {
    return FadeTransition(
      opacity: _fadeAnimations[pageIndex],
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 250,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Main Icon with Statistics
              _buildIconSection(data),

              const SizedBox(height: 40),

              // Title Section
              _buildTitleSection(data),

              const SizedBox(height: 20),

              // Description
              _buildDescription(data),

              const SizedBox(height: 40),

              // Features List
              _buildFeaturesList(data),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconSection(OnboardingData data) {
    return Column(
      children: [
        // Floating Icon
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: data.gradient,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: data.gradient[0].withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  data.icon,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Statistics Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: data.gradient[0].withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: data.gradient[0].withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.statistic,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: data.gradient[0],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                data.statisticLabel,
                style: TextStyle(
                  fontSize: 14,
                  color: data.gradient[0],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection(OnboardingData data) {
    return Column(
      children: [
        Text(
          data.title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          data.subtitle,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: data.gradient[0],
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDescription(OnboardingData data) {
    return Text(
      data.description,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF6B7280),
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFeaturesList(OnboardingData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        children: data.features.map((feature) => _buildFeatureItem(feature, data.gradient[0])).toList(),
      ),
    );
  }

  Widget _buildFeatureItem(OnboardingFeature feature, Color accentColor) {
    final index = _getPages('en')[_currentPage].features.indexOf(feature);

    return Container(
      margin: EdgeInsets.only(bottom: index < 2 ? 16 : 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              feature.icon,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(int totalPages, String language, OnboardingData currentPageData) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        children: [
          // Page Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? currentPageData.gradient[0] : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Navigation Buttons
          Row(
            children: [
              // Back Button
              if (_currentPage > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousPage,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _getTranslation('back', language).isNotEmpty
                          ? _getTranslation('back', language)
                          : 'Back',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ] else
                const Expanded(child: SizedBox()),

              // Next/Get Started Button
              Expanded(
                flex: _currentPage == 0 ? 2 : 1,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentPageData.gradient[0],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == totalPages - 1
                            ? (_getTranslation('get_started', language).isNotEmpty
                            ? _getTranslation('get_started', language)
                            : 'Get Started')
                            : (_getTranslation('next', language).isNotEmpty
                            ? _getTranslation('next', language)
                            : 'Next'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_currentPage == totalPages - 1) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}