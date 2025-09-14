import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String? _selectedLanguageCode;
  bool _isLoading = false;

  // Supported languages list
  static const List<Language> _supportedLanguages = [
    Language(code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸'),
    Language(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    Language(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    Language(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    Language(code: 'it', name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
    Language(code: 'pt', name: 'Portuguese', nativeName: 'Português', flag: '🇵🇹'),
    Language(code: 'ru', name: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
    Language(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
    Language(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    Language(code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
    Language(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
    Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    Language(code: 'ur', name: 'Urdu', nativeName: 'اردو', flag: '🇵🇰'),
    Language(code: 'tr', name: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷'),
    Language(code: 'nl', name: 'Dutch', nativeName: 'Nederlands', flag: '🇳🇱'),
    Language(code: 'sv', name: 'Swedish', nativeName: 'Svenska', flag: '🇸🇪'),
    Language(code: 'da', name: 'Danish', nativeName: 'Dansk', flag: '🇩🇰'),
    Language(code: 'no', name: 'Norwegian', nativeName: 'Norsk', flag: '🇳🇴'),
    Language(code: 'fi', name: 'Finnish', nativeName: 'Suomi', flag: '🇫🇮'),
    Language(code: 'pl', name: 'Polish', nativeName: 'Polski', flag: '🇵🇱'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  void _loadCurrentLanguage() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _selectedLanguageCode = authProvider.getPreference<String>('app_language', 'en');
  }

  Future<void> _updateLanguage(String languageCode) async {
    if (_selectedLanguageCode == languageCode) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Update the language preference
      final success = await authProvider.setPreference('app_language', languageCode);

      if (success) {
        setState(() {
          _selectedLanguageCode = languageCode;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Language updated successfully',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Shorter delay and no restart dialog
        await Future.delayed(Duration(milliseconds: 200));

        // Just pop back - the Consumer will handle the update
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception('Failed to update language preference');
      }
    } catch (e) {
      debugPrint('Error updating language: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update language. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Language Changed'),
        content: Text(
          'The language has been updated. Some changes may require restarting the app to take full effect.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Language? _getLanguageByCode(String code) {
    try {
      return _supportedLanguages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Language Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      )
          : Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Get current language from preferences
          final currentLanguage = authProvider.getPreference<String>('app_language', 'en');

          // Update local state if needed
          if (_selectedLanguageCode != currentLanguage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedLanguageCode = currentLanguage;
              });
            });
          }

          return Column(
            children: [
              // Current language section
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Language',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _getLanguageByCode(_selectedLanguageCode ?? 'en')?.flag ?? '🇺🇸',
                          style: TextStyle(fontSize: 24),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getLanguageByCode(_selectedLanguageCode ?? 'en')?.name ?? 'English',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _getLanguageByCode(_selectedLanguageCode ?? 'en')?.nativeName ?? 'English',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Available languages section
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Available Languages',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.only(bottom: 20),
                          itemCount: _supportedLanguages.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: AppColors.border,
                            indent: 72,
                          ),
                          itemBuilder: (context, index) {
                            final language = _supportedLanguages[index];
                            final isSelected = _selectedLanguageCode == language.code;

                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    language.flag,
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                              title: Text(
                                language.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                language.nativeName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.7)
                                      : AppColors.textSecondary,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 24,
                              )
                                  : null,
                              onTap: () => _updateLanguage(language.code),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info section
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Language changes will be applied immediately. Some text may require an app restart to update fully.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.info,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Language model class
class Language {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}