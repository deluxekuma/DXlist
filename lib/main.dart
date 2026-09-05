import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'pages/home_page.dart';

void main() => runApp(const App());

/// 系統莫奈取色失敗時的備用種子色。
const Color kFallbackSeed = Color(0xFF7B61FF);

class App extends StatelessWidget {
  const App({super.key});

  ThemeData _theme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cubic11',
      colorScheme: scheme,
      // 避免出現純黑底，統一走 M3 的 surface。
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? light, ColorScheme? dark) {
        final lightScheme = light?.harmonized() ??
            ColorScheme.fromSeed(seedColor: kFallbackSeed);
        final darkScheme = dark?.harmonized() ??
            ColorScheme.fromSeed(
              seedColor: kFallbackSeed,
              brightness: Brightness.dark,
            );

        return MaterialApp(
          title: 'DXList',
          debugShowCheckedModeBanner: false,
          theme: _theme(lightScheme),
          darkTheme: _theme(darkScheme),
          home: const HomePage(),
        );
      },
    );
  }
}
