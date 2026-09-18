import 'package:flutter/material.dart';

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ============================================================
  // THEME
  // ============================================================

  static const Color primaryBlue = Color(0xFF079BD3);
  static const Color darkBlue = Color(0xFF102B50);

  bool _navigationStarted = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    debugPrint('SCiRIDER: SplashScreen initState');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startApp();
    });
  }

  // ============================================================
  // START APPLICATION
  // ============================================================

  Future<void> _startApp() async {
    // Prevent duplicate navigation.
    if (_navigationStarted) {
      return;
    }

    _navigationStarted = true;

    try {
      debugPrint(
        '============================================================',
      );
      debugPrint('SCiRIDER: Splash screen displayed');
      debugPrint('SCiRIDER: Waiting before opening LoginScreen');
      debugPrint(
        '============================================================',
      );

      // ----------------------------------------------------------
      // SPLASH DELAY
      // ----------------------------------------------------------

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) {
        debugPrint('SCiRIDER: SplashScreen no longer mounted');

        return;
      }

      // ----------------------------------------------------------
      // OPEN LOGIN
      // ----------------------------------------------------------

      debugPrint(
        '============================================================',
      );
      debugPrint('SCiRIDER: Opening LoginScreen');
      debugPrint(
        '============================================================',
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/login'),
          builder: (BuildContext context) {
            debugPrint('SCiRIDER: LoginScreen builder called');

            return const LoginScreen();
          },
        ),
      );
    } catch (e, stackTrace) {
      debugPrint(
        '============================================================',
      );
      debugPrint('SCiRIDER: SPLASH ERROR');
      debugPrint('$e');
      debugPrint('$stackTrace');
      debugPrint(
        '============================================================',
      );

      // Allow retry if navigation itself failed.
      _navigationStarted = false;

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Unable to start application: '
              '${e.toString().replaceFirst('Exception: ', '')}',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    debugPrint('SCiRIDER: SplashScreen build');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF4FBFF), Color(0xFFEAF8FE)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ==================================================
                  // COMPANY LOGO
                  // ==================================================

                  Container(
                    width: 170,
                    height: 170,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Image.asset(
                        'assets/images/stride_favicon.png',
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,

                        errorBuilder:
                            (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                            ) {
                              debugPrint('SCiRIDER: Splash logo error: $error');

                              return const Icon(
                                Icons.change_history_rounded,
                                size: 100,
                                color: primaryBlue,
                              );
                            },
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // APPLICATION NAME
                  // ==================================================
                  const Text(
                    'SCiRIDER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // APPLICATION SUBTITLE
                  // ==================================================
                  const Text(
                    'ERP Mobile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7892A8),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 45),

                  // ==================================================
                  // LOADER
                  // ==================================================
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: primaryBlue,
                      backgroundColor: Color(0xFFD9EEF8),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // LOADING TEXT
                  // ==================================================
                  const Text(
                    'L O A D I N G . . .',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF91AFC4),
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
