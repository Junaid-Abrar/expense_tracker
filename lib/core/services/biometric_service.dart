import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/translation_helper.dart';

class BiometricService {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastBackgroundTimeKey = 'last_background_time';
  static const String _biometricSessionValidKey = 'biometric_session_valid';
  static const int _sessionTimeoutMinutes = 5; // Session timeout after 5 minutes in background
  
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available and enabled
  static Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Enable or disable biometric authentication
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
      
      if (enabled) {
        // Mark session as valid when first enabled
        await _markSessionValid();
      } else {
        // Clear session when disabled
        await _clearSession();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check if device supports biometric authentication
  static Future<bool> isDeviceSupported() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      return canCheck && isSupported && availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate with biometric
  static Future<bool> authenticate({String? reason, String language = 'en'}) async {
    try {
      if (!await isDeviceSupported()) {
        return false;
      }

      final String localizedReason = reason ?? 
          TranslationHelper.getText('authenticate_app_access', language);

      bool authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        await _markSessionValid();
      }

      return authenticated;
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.message}');
      return false;
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  /// Record app going to background
  static Future<void> onAppBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBackgroundTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check if authentication is required when app comes to foreground
  static Future<bool> shouldRequireAuthentication() async {
    try {
      if (!await isBiometricEnabled()) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final isSessionValid = prefs.getBool(_biometricSessionValidKey) ?? false;
      
      if (!isSessionValid) {
        return true;
      }

      final lastBackgroundTime = prefs.getInt(_lastBackgroundTimeKey);
      if (lastBackgroundTime == null) {
        return false;
      }

      final timeDifference = DateTime.now().millisecondsSinceEpoch - lastBackgroundTime;
      final minutesInBackground = timeDifference / (1000 * 60);

      // Require authentication if app was in background for more than timeout period
      if (minutesInBackground > _sessionTimeoutMinutes) {
        await _clearSession();
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Mark the current session as biometrically valid
  static Future<void> _markSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricSessionValidKey, true);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Clear the biometric session
  static Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricSessionValidKey, false);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Force require authentication on next app access
  static Future<void> invalidateSession() async {
    await _clearSession();
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }
}