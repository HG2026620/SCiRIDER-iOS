import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SCiRIDER is a phone-first ERP application. Keep the application in
  // portrait mode so screens do not stretch/reflow unexpectedly.
  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );

  runApp(const SCiRIDERApp());
}

class SCiRIDERApp extends StatelessWidget {
  const SCiRIDERApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCiRIDER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF079BD3),
          brightness: Brightness.light,
        ),
      ),
      // Prevent extreme device font/display scaling from stretching the ERP UI.
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.90,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
