import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'widgets/app_background.dart';

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
      // 背景交給 AppBackground 疊圖，Scaffold 本身要透明才看得到。
      // AppBackground 底層仍是 scheme.surface，所以純色底沒有被拿掉。
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer.withOpacity(.86),
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
          // 掛在 builder 而不是 home：這樣 SearchPage、DetailPage 這些
          // 推入的路由也同樣疊在背景圖上，不會只有首頁有圖。
          builder: (context, child) =>
              AppBackground(child: child ?? const SizedBox.shrink()),
          home: const HomePage(),
        );
      },
    );
  }
}
