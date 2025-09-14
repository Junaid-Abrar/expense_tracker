import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    if (user != null) {
      _nameController.text = user.displayName;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  Future<void> _showPasswordConfirmationDialog(AuthProvider authProvider) async {
    final passwordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Password"),
        content: TextField(
          controller: passwordController,
          decoration: InputDecoration(hintText: "Enter your password"),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isNotEmpty) {
                await authProvider.deleteAccount(password);
                Navigator.of(context).pop();
              }
            },
            child: Text("Confirm"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Consumer2<AuthProvider, ExpenseProvider>(
        builder: (context, authProvider, expenseProvider, child) {
          final user = authProvider.userModel;

          if (user == null) {
            return const Center(
              child: Text('No user data available'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(user, expenseProvider),
                const SizedBox(height: 32),

                // User Statistics
                _buildUserStatistics(expenseProvider, authProvider),
                const SizedBox(height: 32),

                // Profile Form
                _buildProfileForm(user),
                const SizedBox(height: 32),

                // Account Actions
                if (!_isEditing) _buildAccountActions(authProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user, ExpenseProvider expenseProvider) {
    final initials = user.displayName.isNotEmpty
        ? user.displayName.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.8), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: user.photoURL?.isNotEmpty == true
                  ? CircleAvatar(
                radius: 38,
                backgroundImage: NetworkImage(user.photoURL!),
              )
                  : Text(
                initials,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User Info
          Text(
            user.displayName.isNotEmpty ? user.displayName : 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          // Member Since
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Member since ${_formatDate(user.createdAt)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatistics(ExpenseProvider expenseProvider, AuthProvider authProvider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Today at 00:00:00
    
    // Define clear date ranges
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    final thisYearStart = DateTime(now.year, 1, 1);
    final thisYearEnd = DateTime(now.year, 12, 31);

    // Filter expenses with better logic (exclude future expenses)
    final thisMonthExpenses = expenseProvider.expenses.where((expense) {
      final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      return expenseDate.isAfter(thisMonthStart.subtract(const Duration(days: 1))) &&
             expenseDate.isBefore(thisMonthEnd.add(const Duration(days: 1))) &&
             expenseDate.isBefore(today.add(const Duration(days: 1))); // Don't include future expenses
    }).toList();

    final thisYearExpenses = expenseProvider.expenses.where((expense) {
      final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      return expenseDate.isAfter(thisYearStart.subtract(const Duration(days: 1))) &&
             expenseDate.isBefore(thisYearEnd.add(const Duration(days: 1))) &&
             expenseDate.isBefore(today.add(const Duration(days: 1))); // Don't include future expenses
    }).toList();

    // Calculate totals
    final thisMonthTotal = thisMonthExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final thisYearTotal = thisYearExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final totalTransactions = thisYearExpenses.length; // More relevant than all-time count
    
    // Better monthly average calculation
    double avgMonthly = 0.0;
    if (thisYearTotal > 0) {
      // Calculate elapsed months more accurately
      final daysSinceYearStart = today.difference(thisYearStart).inDays + 1;
      final monthsElapsed = daysSinceYearStart / 30.44; // Average days per month
      avgMonthly = monthsElapsed > 0 ? thisYearTotal / monthsElapsed : thisYearTotal;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'This Month',
                authProvider.formatCurrency(thisMonthTotal),
                Icons.calendar_month,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'This Year',
                authProvider.formatCurrency(thisYearTotal),
                Icons.calendar_today,
                AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'This Year Transactions',
                totalTransactions.toString(),
                Icons.receipt_long,
                AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Monthly Average',
                authProvider.formatCurrency(avgMonthly),
                Icons.trending_up,
                AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Profile Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_isEditing)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
          ],
        ),
        const SizedBox(height: 16),

        Form(
          key: _formKey,
          child: Column(
            children: [
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  enabled: _isEditing,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  enabled: false, // Email usually can't be changed
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  enabled: _isEditing,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),

              if (_isEditing) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountActions(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Change Password - only show for email/password users
        if (_isEmailPasswordUser(authProvider))
          _buildActionCard(
            'Change Password',
            'Update your account password',
            Icons.lock,
            AppColors.primary,
                () => _showChangePasswordDialog(),
          )
        else
          _buildActionCard(
            'Change Password',
            'Not available for Google accounts',
            Icons.lock,
            Colors.grey,
                () => _showPasswordNotAvailableDialog(),
          ),
        const SizedBox(height: 12),

        // Export Data
        _buildActionCard(
          'Export Data',
          'Download your expense data',
          Icons.download,
          AppColors.secondary,
              () => _exportData(),
        ),
        const SizedBox(height: 12),

        // Delete Account
        _buildActionCard(
          'Delete Account',
          'Permanently delete your account',
          Icons.delete_forever,
          AppColors.error,
              () => _showDeleteAccountDialog(authProvider),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    _loadUserData(); // Reset form data
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Update user profile
      await authProvider.updateProfile(
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Profile updated successfully'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.lock, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter your current password and choose a new one.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Error display
                          if (errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.error_outline, color: AppColors.error, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Current Password
                          TextFormField(
                            controller: currentPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscureCurrentPassword = !obscureCurrentPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            obscureText: obscureCurrentPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter current password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // New Password
                          TextFormField(
                            controller: newPasswordController,
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: const Icon(Icons.lock_reset, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscureNewPassword = !obscureNewPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            obscureText: obscureNewPassword,
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              if (value == currentPasswordController.text) {
                                return 'New password must be different from current password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Confirm Password
                          TextFormField(
                            controller: confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
                              prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscureConfirmPassword = !obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            obscureText: obscureConfirmPassword,
                            validator: (value) {
                              if (value != newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Info box
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Use a strong password with at least 6 characters',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          if (!formKey.currentState!.validate()) return;

                          setState(() {
                            isLoading = true;
                          });

                          try {
                            // Clear any previous error
                            setState(() {
                              errorMessage = null;
                            });
                            
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final success = await authProvider.updatePassword(
                              currentPasswordController.text,
                              newPasswordController.text,
                            );

                            if (success) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Password changed successfully!'),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              // Show error within the dialog instead of snackbar
                              setState(() {
                                errorMessage = authProvider.errorMessage ?? 'Failed to change password. Please try again.';
                              });
                            }
                          } catch (e) {
                            // Show error within the dialog instead of snackbar
                            setState(() {
                              errorMessage = 'Failed to change password: ${e.toString()}';
                            });
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Update'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _exportData() {
    // Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality will be implemented soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteAccountDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                await _showPasswordConfirmationDialog(authProvider);
                // Navigate to login screen or handle account deletion
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete account: ${e.toString()}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  // Helper method to check if user signed in with email/password
  bool _isEmailPasswordUser(AuthProvider authProvider) {
    final user = authProvider.user;
    if (user == null) return false;
    
    for (final info in user.providerData) {
      if (info.providerId == 'password') {
        return true;
      }
    }
    return false;
  }

  void _showPasswordNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Password Change Not Available')),
          ],
        ),
        content: const Text(
          'You signed in using Google. Password changes are only available for accounts created with email and password.\n\nTo manage your Google account password, please visit your Google Account settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${months[date.month - 1]} ${date.year}';
  }
}