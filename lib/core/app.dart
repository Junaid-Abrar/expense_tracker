import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../routes/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        final user = authProvider.userModel;

        return MaterialApp.router(
          title: 'Safar',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          locale: Locale(
            user?.locale?.split('_').first ?? 'en',
          ),
          supportedLocales: const [
            Locale('en'),
            Locale('ur'),
            Locale('fr'),
            Locale('de'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: AppRouter.createRouter(authProvider),
        );
      },
    );
  }
}