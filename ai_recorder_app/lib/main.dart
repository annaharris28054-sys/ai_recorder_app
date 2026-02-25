import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routing/app_router.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const AiRecorderApp());
}

class AiRecorderApp extends StatelessWidget {
  const AiRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: Builder(
        builder: (context) {
          final router = createAppRouter(context.read<AppState>());

          return MaterialApp.router(
            title: 'AI 智能录音机',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            routerConfig: router,
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    const primaryColor = Color(0xFF4C4DDC);
    const darkBackground = Color(0xFF15162B);
    const lightBackground = Color(0xFFF5F7FA);

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ),
      scaffoldBackgroundColor:
          brightness == Brightness.dark ? darkBackground : lightBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      fontFamily: 'Roboto',
    );

    return baseTheme;
  }
}

