import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/constants/app_colors.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String _selectedCurrency = 'USD';
  String _selectedDateFormat = 'DD/MM/YYYY';
  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;
  bool _budgetAlertsEnabled = true;
  bool _expenseRemindersEnabled = false;
  bool _monthlyReportsEnabled = true;
  bool _biometricEnabled = false;
  bool _autoBackupEnabled = true;
  String _backupFrequency = 'Daily';

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
    {'code': 'PKR', 'name': 'Pakistani Rupee', 'symbol': '₨'},
  ];

  final List<String> _dateFormats = [
    'DD/MM/YYYY',
    'MM/DD/YYYY',
    'YYYY-MM-DD',
    'DD-MM-YYYY',
    'MM-DD-YYYY',
  ];

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Chinese',
    'Japanese',
    'Arabic',
    'Urdu',
  ];

  final List<String> _backupFrequencies = [
    'Daily',
    'Weekly',
    'Monthly',
    'Manual',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        elevation: 0,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Appearance Section
              _buildSectionTitle('Appearance'),
              const SizedBox(height: 12),
              _buildAppearanceCard(themeProvider),
              const SizedBox(height: 24),

              // Regional Settings
              _buildSectionTitle('Regional Settings'),
              const SizedBox(height: 12),
              _buildRegionalCard(),
              const SizedBox(height: 24),

              // Notifications
              _buildSectionTitle('Notifications'),
              const SizedBox(height: 12),
              _buildNotificationsCard(),
              const SizedBox(height: 24),

              // Security
              _buildSectionTitle('Security'),
              const SizedBox(height: 12),
              _buildSecurityCard(),
              const SizedBox(height: 24),

              // Backup & Sync
              _buildSectionTitle('Backup & Sync'),
              const SizedBox(height: 12),
              _buildBackupCard(),
              const SizedBox(height: 24),

              // Advanced
              _buildSectionTitle('Advanced'),
              const SizedBox(height: 12),
              _buildAdvancedCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAppearanceCard(ThemeProvider themeProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Theme Selection
            _buildPreferenceItem(
              'Theme',
              'Choose your preferred theme',
              Icons.palette,
              trailing: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto, size: 16),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.brightness_high, size: 16),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.brightness_4, size: 16),
                  ),
                ],
                selected: {themeProvider.themeMode},
                onSelectionChanged: (Set<ThemeMode> selection) {
                  themeProvider.setThemeMode(selection.first);
                },
                style: ButtonStyle(
                  textStyle: MaterialStateProperty.all(
                    const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
            const Divider(),

            // Accent Color
            _buildPreferenceItem(
              'Accent Color',
              'Customize app colors',
              Icons.color_lens,
              onTap: () => _showColorPicker(),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionalCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Currency
            _buildPreferenceItem(
              'Currency',
              _currencies.firstWhere((c) => c['code'] == _selectedCurrency)['name']!,
              Icons.attach_money,
              onTap: () => _showCurrencyPicker(),
              trailing: Text(
                _currencies.firstWhere((c) => c['code'] == _selectedCurrency)['symbol']!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const Divider(),

            // Date Format
            _buildPreferenceItem(
              'Date Format',
              _selectedDateFormat,
              Icons.calendar_today,
              onTap: () => _showDateFormatPicker(),
            ),
            const Divider(),

            // Language
            _buildPreferenceItem(
              'Language',
              _selectedLanguage,
              Icons.language,
              onTap: () => _showLanguagePicker(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Enable Notifications
            _buildSwitchItem(
              'Enable Notifications',
              'Receive app notifications',
              Icons.notifications,
              _notificationsEnabled,
                  (value) => setState(() => _notificationsEnabled = value),
            ),
            const Divider(),

            // Budget Alerts
            _buildSwitchItem(
              'Budget Alerts',
              'Notify when approaching budget limits',
              Icons.warning,
              _budgetAlertsEnabled,
                  (value) => setState(() => _budgetAlertsEnabled = value),
              enabled: _notificationsEnabled,
            ),
            const Divider(),

            // Expense Reminders
            _buildSwitchItem(
              'Expense Reminders',
              'Daily reminders to log expenses',
              Icons.alarm,
              _expenseRemindersEnabled,
                  (value) => setState(() => _expenseRemindersEnabled = value),
              enabled: _notificationsEnabled,
            ),
            const Divider(),

            // Monthly Reports
            _buildSwitchItem(
              'Monthly Reports',
              'Receive monthly spending summaries',
              Icons.report,
              _monthlyReportsEnabled,
                  (value) => setState(() => _monthlyReportsEnabled = value),
              enabled: _notificationsEnabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Biometric Authentication
            _buildSwitchItem(
              'Biometric Login',
              'Use fingerprint or face recognition',
              Icons.fingerprint,
              _biometricEnabled,
                  (value) => setState(() => _biometricEnabled = value),
            ),
            const Divider(),

            // App Lock
            _buildPreferenceItem(
              'App Lock Timer',
              'Lock app after inactivity',
              Icons.lock_clock,
              onTap: () => _showAppLockDialog(),
              trailing: const Text('5 minutes'),
            ),
            const Divider(),

            // Privacy Settings
            _buildPreferenceItem(
              'Privacy Settings',
              'Manage data sharing preferences',
              Icons.privacy_tip,
              onTap: () => _showPrivacySettings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Auto Backup
            _buildSwitchItem(
              'Auto Backup',
              'Automatically backup your data',
              Icons.cloud_upload,
              _autoBackupEnabled,
                  (value) => setState(() => _autoBackupEnabled = value),
            ),
            const Divider(),

            // Backup Frequency
            _buildPreferenceItem(
              'Backup Frequency',
              _backupFrequency,
              Icons.schedule,
              onTap: () => _showBackupFrequencyPicker(),
              enabled: _autoBackupEnabled,
            ),
            const Divider(),

            // Manual Backup
            _buildPreferenceItem(
              'Manual Backup',
              'Create backup now',
              Icons.backup,
              onTap: () => _performManualBackup(),
            ),
            const Divider(),

            // Restore Data
            _buildPreferenceItem(
              'Restore Data',
              'Restore from backup',
              Icons.restore,
              onTap: () => _showRestoreDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Reset Settings
            _buildPreferenceItem(
              'Reset Settings',
              'Reset all preferences to default',
              Icons.refresh,
              onTap: () => _showResetDialog(),
              trailing: Icon(
                Icons.warning,
                color: AppColors.warning,
                size: 20,
              ),
            ),
            const Divider(),

            // Clear Cache
            _buildPreferenceItem(
              'Clear Cache',
              'Free up storage space',
              Icons.cleaning_services,
              onTap: () => _clearCache(),
            ),
            const Divider(),

            // Debug Mode
            _buildSwitchItem(
              'Debug Mode',
              'Enable developer options',
              Icons.bug_report,
              false,
                  (value) => _showDebugWarning(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceItem(
      String title,
      String subtitle,
      IconData icon, {
        VoidCallback? onTap,
        Widget? trailing,
        bool enabled = true,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? AppColors.primary : Theme.of(context).disabledColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: enabled ? null : Theme.of(context).disabledColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled
              ? Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)
              : Theme.of(context).disabledColor,
        ),
      ),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
      onTap: enabled ? onTap : null,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSwitchItem(
      String title,
      String subtitle,
      IconData icon,
      bool value,
      ValueChanged<bool> onChanged, {
        bool enabled = true,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? AppColors.primary : Theme.of(context).disabledColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: enabled ? null : Theme.of(context).disabledColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled
              ? Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)
              : Theme.of(context).disabledColor,
        ),
      ),
      trailing: Switch(
        value: enabled ? value : false,
        onChanged: enabled ? onChanged : null,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showColorPicker() {
    final colors = [
      AppColors.primary,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Accent Color'),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                // Update accent color (implement in theme provider)
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _currencies.length,
            itemBuilder: (context, index) {
              final currency = _currencies[index];
              final isSelected = currency['code'] == _selectedCurrency;

              return ListTile(
                leading: Text(
                  currency['symbol']!,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                title: Text(currency['name']!),
                subtitle: Text(currency['code']!),
                trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() {
                    _selectedCurrency = currency['code']!;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDateFormatPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Date Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _dateFormats.map((format) {
            final isSelected = format == _selectedDateFormat;

            return ListTile(
              title: Text(format),
              subtitle: Text(_getDateExample(format)),
              trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() {
                  _selectedDateFormat = format;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final language = _languages[index];
              final isSelected = language == _selectedLanguage;

              return ListTile(
                title: Text(language),
                trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() {
                    _selectedLanguage = language;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showBackupFrequencyPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _backupFrequencies.map((frequency) {
            final isSelected = frequency == _backupFrequency;

            return ListTile(
              title: Text(frequency),
              trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() {
                  _backupFrequency = frequency;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAppLockDialog() {
    final options = ['1 minute', '5 minutes', '15 minutes', '30 minutes', '1 hour', 'Never'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Lock Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return ListTile(
              title: Text(option),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('App lock set to $option')),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPrivacySettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Privacy Settings')),
          body: const Center(child: Text('Privacy settings will be implemented')),
        ),
      ),
    );
  }

  void _performManualBackup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating backup...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Backup created successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    });
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text('This will replace all current data with backup data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement restore functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restore functionality will be implemented')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('This will reset all preferences to default values. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Clearing cache...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cache cleared successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    });
  }

  void _showDebugWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Mode'),
        content: const Text('Debug mode is for developers only. Enable it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debug mode enabled')),
              );
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    setState(() {
      _selectedCurrency = 'USD';
      _selectedDateFormat = 'DD/MM/YYYY';
      _selectedLanguage = 'English';
      _notificationsEnabled = true;
      _budgetAlertsEnabled = true;
      _expenseRemindersEnabled = false;
      _monthlyReportsEnabled = true;
      _biometricEnabled = false;
      _autoBackupEnabled = true;
      _backupFrequency = 'Daily';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings reset to default'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _getDateExample(String format) {
    final now = DateTime.now();
    switch (format) {
      case 'DD/MM/YYYY':
        return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      case 'MM/DD/YYYY':
        return '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
      case 'YYYY-MM-DD':
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case 'DD-MM-YYYY':
        return '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      case 'MM-DD-YYYY':
        return '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.year}';
      default:
        return format;
    }
  }
}