import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/biometric_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../core/utils/translation_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'en_US';
  String _selectedCurrency = 'USD (\$)';

  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  void _loadUserPreferences() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    if (user != null) {
      setState(() {
        _notificationsEnabled = user.notificationsEnabled;
        _biometricEnabled = user.biometricEnabled;
        _selectedLanguage = user.language ?? 'en_US';
        _selectedCurrency = user.currency ?? 'USD (\$)';
      });
    }
  }

  String _getTranslation(String key, String language) {
    return TranslationHelper.getText(key, language);
  }

  Future<void> _signOut(String language) async {
    final confirmed = await _showSignOutDialog(language);
    if (confirmed && mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signOut();
      if (mounted) {
        context.go('/auth/login');
      }
    }
  }

  Future<bool> _showSignOutDialog(String language) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getTranslation('sign_out', language)),
        content: Text(_getTranslation('sign_out_confirmation', language)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_getTranslation('cancel', language)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(_getTranslation('sign_out', language)),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _changePassword(String language) async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getTranslation('change_password', language)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldController,
                obscureText: true,
                decoration: InputDecoration(labelText: _getTranslation('current_password', language)),
                validator: (value) =>
                (value == null || value.isEmpty) ? _getTranslation('enter_current_password', language) : null,
              ),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: InputDecoration(labelText: _getTranslation('new_password', language)),
                validator: (value) => (value == null || value.length < 6)
                    ? _getTranslation('password_min_length', language)
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_getTranslation('cancel', language))),
          ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: Text(_getTranslation('update', language))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authProvider = context.read<AuthProvider>();
        await authProvider.updatePassword(oldController.text, newController.text);
        _showSnackBar(_getTranslation('password_updated_successfully', language));
      } catch (e) {
        _showSnackBar('${_getTranslation('failed_to_update_password', language)}: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final language = authProvider.getPreference<String>('app_language', 'en');

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(_getTranslation('settings', language)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildCompactProfileCard(language),
                const SizedBox(height: 24),
                _buildQuickActionsRow(language),
                const SizedBox(height: 24),
                _buildAppPreferences(language),
                const SizedBox(height: 16),
                _buildSecuritySettings(language),
                const SizedBox(height: 16),
                _buildSupportAndInfo(language),
                const SizedBox(height: 32),
                _buildSignOutButton(language),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactProfileCard(String language) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: user?.photoURL != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.network(
                    user!.photoURL!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person, size: 30, color: Colors.white),
                  ),
                )
                    : const Icon(Icons.person, size: 30, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? _getTranslation('user', language),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push('/settings/profile'),
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsRow(String language) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.account_balance_wallet_outlined,
              title: _getTranslation('payment_methods', language),
              onTap: () => context.push('/settings/payment-methods'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.history,
              title: _getTranslation('transaction_history', language),
              onTap: () => context.push('/settings/transaction-history'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppPreferences(String language) {
    return _buildModernSection(
      title: _getTranslation('app_preferences', language),
      children: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return _buildModernSettingsItem(
              icon: Icons.palette_outlined,
              title: _getTranslation('theme', language),
              subtitle: _getThemeName(themeProvider.themeMode, language),
              trailing: _buildThemeSelector(themeProvider, language),
            );
          },
        ),
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return _buildModernSettingsItem(
              icon: Icons.language_outlined,
              title: _getTranslation('language', language),
              subtitle: _getLanguageName(authProvider.getPreference<String>('app_language', 'en'), language),
              onTap: () => context.push('/settings/language'),
            );
          },
        ),
        _buildModernSettingsItem(
          icon: Icons.attach_money,
          title: _getTranslation('currency', language),
          subtitle: _selectedCurrency,
          onTap: () => context.push('/settings/currency'),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings(String language) {
    return _buildModernSection(
      title: _getTranslation('security_privacy', language),
      children: [
        _buildModernSettingsItem(
          icon: Icons.notifications_outlined,
          title: _getTranslation('push_notifications', language),
          subtitle: _notificationsEnabled
              ? _getTranslation('enabled', language)
              : _getTranslation('disabled', language),
          trailing: Switch.adaptive(
            value: _notificationsEnabled,
            onChanged: (value) async {
              if (value) {
                // Ensure service is initialized
                await NotificationService.initialize();

                // Request permission when enabling
                final hasPermission = await NotificationService.requestPermissions();

                if (hasPermission) {
                  setState(() => _notificationsEnabled = true);
                  final authProvider = context.read<AuthProvider>();
                  await authProvider.updateProfile(notificationsEnabled: true);

                  // Show success message
                  _showSnackBar(_getTranslation('notifications_enabled', language));

                  // Send a test notification
                  await NotificationService.showLocalNotification(
                    title: _getTranslation('notifications_enabled', language),
                    body: _getTranslation('notification_test_message', language),
                  );

                  // Schedule a daily reminder (optional)
                  await NotificationService.scheduleDailyReminder(
                    title: 'Expense Reminder',
                    body: 'Don\'t forget to track your expenses today!',
                    hour: 20, // 8 PM
                    minute: 0,
                  );
                } else {
                  _showSnackBar(_getTranslation('notification_permission_denied', language), isError: true);
                }
              } else {
                setState(() => _notificationsEnabled = false);
                final authProvider = context.read<AuthProvider>();
                await authProvider.updateProfile(notificationsEnabled: false);

                // Cancel all notifications when disabled
                await NotificationService.cancelAllNotifications();
                _showSnackBar(_getTranslation('notifications_disabled', language));
              }
            },
            activeColor: AppColors.primary,
          ),
        ),
        _buildModernSettingsItem(
          icon: Icons.fingerprint,
          title: _getTranslation('biometric_login', language),
          subtitle: _biometricEnabled ? _getTranslation('enabled', language) : _getTranslation('disabled', language),
          trailing: Switch.adaptive(
            value: _biometricEnabled,
            onChanged: (value) async {
              if (value) {
                try {
                  // Check if biometrics are supported using the BiometricService
                  if (!await BiometricService.isDeviceSupported()) {
                    _showSnackBar(_getTranslation('biometric_not_supported', language), isError: true);
                    return;
                  }

                  // Authenticate to enable biometric
                  bool authenticated = await BiometricService.authenticate(
                    reason: _getTranslation('authenticate_enable_biometric', language),
                    language: language,
                  );

                  if (authenticated) {
                    setState(() => _biometricEnabled = true);
                    await context.read<AuthProvider>().updateProfile(biometricEnabled: true);
                    await BiometricService.setBiometricEnabled(true);
                    _showSnackBar(_getTranslation('biometric_enabled', language));
                  }
                } catch (e) {
                  _showSnackBar('${_getTranslation('authentication_failed', language)}: $e', isError: true);
                }
              } else {
                setState(() => _biometricEnabled = false);
                await context.read<AuthProvider>().updateProfile(biometricEnabled: false);
                await BiometricService.setBiometricEnabled(false);
                _showSnackBar(_getTranslation('biometric_disabled', language));
              }
            },
            activeColor: AppColors.primary,
          ),
        ),
        _buildModernSettingsItem(
          icon: Icons.lock_outline,
          title: _getTranslation('change_password', language),
          subtitle: _getTranslation('update_account_password', language),
          onTap: () => _changePassword(language),
        ),
      ],
    );
  }

  Widget _buildSupportAndInfo(String language) {
    return _buildModernSection(
      title: _getTranslation('support_information', language),
      children: [
        _buildModernSettingsItem(
          icon: Icons.help_outline,
          title: _getTranslation('help_center', language),
          subtitle: _getTranslation('faqs_guides', language),
          onTap: () => context.push('/settings/support/help-center'),
        ),
        _buildModernSettingsItem(
          icon: Icons.feedback_outlined,
          title: _getTranslation('send_feedback', language),
          subtitle: _getTranslation('share_thoughts', language),
          onTap: () => context.push('/settings/support/send-feedback'),
        ),
        _buildModernSettingsItem(
          icon: Icons.info_outline,
          title: _getTranslation('about', language),
          subtitle: _getTranslation('version_info', language),
          onTap: () => context.push('/settings/support/about'),
        ),
      ],
    );
  }

  Widget _buildModernSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
      trailing: trailing ??
          (onTap != null ? Icon(Icons.chevron_right, color: Colors.grey[400]) : null),
      onTap: onTap,
    );
  }

  Widget _buildThemeSelector(ThemeProvider themeProvider, String language) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<ThemeMode>(
        value: themeProvider.themeMode,
        underline: const SizedBox(),
        isDense: true,
        items: [
          DropdownMenuItem(value: ThemeMode.system, child: Text(_getTranslation('system', language))),
          DropdownMenuItem(value: ThemeMode.light, child: Text(_getTranslation('light', language))),
          DropdownMenuItem(value: ThemeMode.dark, child: Text(_getTranslation('dark', language))),
        ],
        onChanged: (ThemeMode? mode) {
          if (mode != null) {
            themeProvider.setThemeMode(mode);
          }
        },
      ),
    );
  }

  Widget _buildSignOutButton(String language) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _signOut(language),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: AppColors.error, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _getTranslation('sign_out', language),
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode, String language) {
    switch (mode) {
      case ThemeMode.light:
        return _getTranslation('light_mode', language);
      case ThemeMode.dark:
        return _getTranslation('dark_mode', language);
      case ThemeMode.system:
        return _getTranslation('system_default', language);
    }
  }

  String _getLanguageName(String languageCode, String language) {
    switch (languageCode) {
      case 'en':
        return _getTranslation('english', language);
      case 'es':
        return _getTranslation('spanish', language);
      case 'fr':
        return _getTranslation('french', language);
      case 'it':
        return _getTranslation('italian', language);
      case 'de':
        return _getTranslation('german', language);
      case 'zh':
        return _getTranslation('chinese', language);
      case 'ja':
        return _getTranslation('japanese', language);
      case 'ko':
        return _getTranslation('korean', language);
      case 'ar':
        return _getTranslation('arabic', language);
      case 'hi':
        return _getTranslation('hindi', language);
      case 'ur':
        return _getTranslation('urdu', language);
      case 'tr':
        return _getTranslation('turkish', language);
      case 'nl':
        return _getTranslation('dutch', language);
      case 'sv':
        return _getTranslation('swedish', language);
      case 'da':
        return _getTranslation('danish', language);
      default:
        return _getTranslation('english', language);
    }
  }
}