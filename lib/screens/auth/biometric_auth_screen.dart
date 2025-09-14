import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/services/biometric_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/translation_helper.dart';

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> with TickerProviderStateMixin {
  bool _isAuthenticating = false;
  String _errorMessage = '';
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    
    _pulseController.repeat(reverse: true);
    
    // Auto-trigger biometric authentication
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateWithBiometric();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String _getTranslation(String key) {
    final language = context.read<AuthProvider>().getPreference<String>('app_language', 'en');
    return TranslationHelper.getText(key, language);
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      final language = context.read<AuthProvider>().getPreference<String>('app_language', 'en');
      final authenticated = await BiometricService.authenticate(
        reason: _getTranslation('authenticate_app_access'),
        language: language,
      );

      if (authenticated) {
        if (mounted) {
          context.go('/home');
        }
      } else {
        setState(() {
          _errorMessage = _getTranslation('authentication_failed');
        });
        _shakeController.forward().then((_) {
          _shakeController.reset();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getTranslation('authentication_error');
      });
      _shakeController.forward().then((_) {
        _shakeController.reset();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signOut();
      await BiometricService.setBiometricEnabled(false);
      if (mounted) {
        context.go('/auth/login');
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getTranslation('sign_out_failed');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // App Icon/Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // App Title
                Text(
                  _getTranslation('expense_tracker'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Subtitle
                Text(
                  _getTranslation('secure_access_required'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 60),
                
                // Biometric Icon with Animation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: FutureBuilder<List<BiometricType>>(
                                future: BiometricService.getAvailableBiometrics(),
                                builder: (context, snapshot) {
                                  IconData icon = Icons.fingerprint;
                                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                    final biometrics = snapshot.data!;
                                    if (biometrics.contains(BiometricType.face)) {
                                      icon = Icons.face;
                                    } else if (biometrics.contains(BiometricType.fingerprint)) {
                                      icon = Icons.fingerprint;
                                    }
                                  }
                                  
                                  return Icon(
                                    icon,
                                    size: 48,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Status Text
                if (_isAuthenticating)
                  Column(
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getTranslation('authenticating'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        _getTranslation('tap_to_authenticate'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                
                const Spacer(flex: 2),
                
                // Action Buttons
                Column(
                  children: [
                    // Try Again Button
                    if (!_isAuthenticating && _errorMessage.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _authenticateWithBiometric,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _getTranslation('try_again'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Sign Out Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _signOut,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _getTranslation('sign_out'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}