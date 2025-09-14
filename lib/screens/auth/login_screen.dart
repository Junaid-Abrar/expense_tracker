import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';
import '../../routes/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isGoogleSignInPressed = false;
  bool _isEmailLoginLoading = false; // Local state for email/password login

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Use local loading state to prevent provider rebuilds
    setState(() {
      _isEmailLoginLoading = true;
    });

    final authProvider = context.read<AuthProvider>();

    // Clear any existing errors first
    authProvider.clearError();

    final success = await authProvider.signInWithEmailPassword(
      _emailController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isEmailLoginLoading = false;
      });

      if (success) {
        context.go('/home');
      } else if (authProvider.errorMessage != null) {
        _showErrorSnackBar(authProvider.errorMessage!);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: SafeArea(
        child: Selector<AuthProvider, String?>(
          selector: (context, authProvider) => authProvider.errorMessage,
          builder: (context, errorMessage, child) {
            // Use local loading state instead of provider state to prevent rebuilds
            final isAuthenticating = false; // We'll use local state for loading
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Logo and welcome text
                  _buildHeader(),

                  const SizedBox(height: 32),

                  // Error message display (alternative to snackbar)
                  if (errorMessage != null)
                    _buildErrorCard(errorMessage),

                  // Login form
                  _buildLoginForm(),

                  const SizedBox(height: 20),

                  // Remember me and forgot password
                  _buildRememberAndForgot(),

                  const SizedBox(height: 24),

                  // Login button
                  _buildLoginButton(_isEmailLoginLoading),

                  const SizedBox(height: 24),

                  // Divider
                  _buildDivider(),

                  const SizedBox(height: 24),

                  // Social login buttons
                  _buildSocialLogin(isAuthenticating, errorMessage),

                  const SizedBox(height: 32),

                  // Sign up link
                  _buildSignUpLink(),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              final authProvider = context.read<AuthProvider>();
              authProvider.clearError();
            },
            icon: Icon(Icons.close, color: AppColors.error),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2);
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            size: 40,
            color: Colors.white,
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(delay: 200.ms),

        const SizedBox(height: 16),

        Text(
          'Welcome Back!',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        )
            .animate()
            .fadeIn(delay: 300.ms)
            .slideX(begin: -0.3, duration: 600.ms),

        const SizedBox(height: 8),

        Text(
          'Sign in to continue managing your expenses',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 400.ms)
            .slideX(begin: 0.3, duration: 600.ms),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          )
              .animate()
              .fadeIn(delay: 500.ms)
              .slideY(begin: 0.3, duration: 600.ms),

          const SizedBox(height: 16),

          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            hintText: 'Enter your password',
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outlined,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          )
              .animate()
              .fadeIn(delay: 600.ms)
              .slideY(begin: 0.3, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildRememberAndForgot() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: AppColors.primary,
              ),
              const Text('Remember me'),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            _showForgotPasswordDialog();
          },
          child: const Text('Forgot Password?'),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildLoginButton(bool isAuthenticating) {
    return CustomButton(
      text: 'Sign In',
      onPressed: _handleLogin,
      isLoading: isAuthenticating,
      gradient: AppColors.primaryGradient,
    ).animate().fadeIn(delay: 800.ms).scale(delay: 800.ms);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    ).animate().fadeIn(delay: 900.ms);
  }

  Widget _buildSocialLogin(bool isAuthenticating, String? errorMessage) {
    return Builder(
      builder: (context) {
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isGoogleSignInPressed ? null : () async {
                setState(() {
                  _isGoogleSignInPressed = true;
                });
                
                try {
                  final authProvider = context.read<AuthProvider>();
                  final success = await authProvider.signInWithGoogle();
                  if (success && mounted) {
                    context.go('/home');
                  } else if (mounted && authProvider.errorMessage != null) {
                    _showErrorSnackBar(authProvider.errorMessage!);
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isGoogleSignInPressed = false;
                    });
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isGoogleSignInPressed)
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 12),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      )
                    else
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Image.asset(
                          'assets/images/google_logo.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to a custom Google "G" if image not found
                            return Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4285f4),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    Text(
                      _isGoogleSignInPressed
                          ? 'Signing in with Google...'
                          : 'Continue with Google',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).animate().fadeIn(delay: 1000.ms);
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        TextButton(
          onPressed: () => context.go('/auth/register'),
          child: const Text('Sign Up'),
        ),
      ],
    ).animate().fadeIn(delay: 1100.ms);
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive password reset instructions.'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: emailController,
              label: 'Email',
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                final authProvider = context.read<AuthProvider>();
                final success = await authProvider.resetPassword(emailController.text);

                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    _showSuccessSnackBar('Password reset email sent!');
                  } else {
                    _showErrorSnackBar(authProvider.errorMessage ?? 'Failed to send reset email');
                  }
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}