import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
// import '../../widgets/common/custom_button.dart';
// import '../../widgets/common/custom_text_field.dart';
// import '../../core/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      // Clear any existing errors
      authProvider.clearError();

      final success = await authProvider.signUpWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (success && mounted) {
        _showSuccessSnackBar('Account created successfully!');
        // No need to delay or go to login
        context.go('/home');
      } else if (mounted) {
        _showErrorSnackBar(authProvider.errorMessage ?? 'Registration failed');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Simple validation methods
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildRegisterForm(),
                  const SizedBox(height: 30),
                  _buildRegisterButton(),
                  const SizedBox(height: 20),
                  _buildSignInLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Create Account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join us and start tracking your expenses',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            hintText: 'Full Name',
            prefixIcon: Icons.person_outline,
            validator: _validateName,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            hintText: 'Email Address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            hintText: 'Password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            validator: _validatePassword,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm Password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            validator: _validateConfirmPassword,
            textInputAction: TextInputAction.done,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
            onFieldSubmitted: (_) => _handleRegister(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Text(
              'Sign In',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}