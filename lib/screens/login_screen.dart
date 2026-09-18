import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color sciBlue = Color(0xFF079BD3);
  static const Color sciNavy = Color(0xFF173F6B);
  static const Color sciGreen = Color(0xFF55B947);

  static const Color pageBackground = Color(0xFFF4F8FB);
  static const Color fieldBackground = Color(0xFFF8FAFC);
  static const Color fieldBorder = Color(0xFFDCE5EA);
  static const Color secondaryText = Color(0xFF8A9AA6);

  final AuthService _authService = AuthService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _loginIdController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final FocusNode _loginFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();

    debugPrint('SCiRIDER: LoginScreen initState');
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();

    _loginFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoggingIn) {
      return;
    }

    FocusScope.of(context).unfocus();

    final bool valid =
        _formKey.currentState?.validate() ?? false;

    if (!valid) {
      return;
    }

    final String loginId =
        _loginIdController.text.trim();

    final String password =
        _passwordController.text;

    setState(() {
      _isLoggingIn = true;
    });

    // Give Flutter one frame to render the waiting overlay before
    // the authentication request starts.
    await Future<void>.delayed(const Duration(milliseconds: 120));

    if (!mounted) {
      return;
    }

    try {
      debugPrint(
        'SCiRIDER: Starting login for $loginId',
      );

      final result = await _authService.login(
        loginId: loginId,
        password: password,
      );

      if (!mounted) {
        return;
      }

      if (!result.success) {
        _showMessage(
          result.message.trim().isEmpty
              ? 'Login failed. Please check your credentials.'
              : result.message,
        );

        return;
      }

      final user = result.user;

      if (user == null) {
        _showMessage(
          'Login successful, but user profile was not returned.',
        );

        return;
      }

      debugPrint(
        'SCiRIDER: Login successful',
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            user: user,
          ),
        ),
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint(
        'SCiRIDER LOGIN ERROR: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      String message =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      if (message.trim().isEmpty) {
        message =
            'Unable to connect to SCiRIDER.';
      }

      _showMessage(
        message.trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'SCiRIDER: LoginScreen build',
    );

    return Scaffold(
      backgroundColor: pageBackground,
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildBackground(),
            ),

            Positioned.fill(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .onDrag,

                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  30,
                  20,
                  30,
                ),

                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 480,
                    ),

                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,

                      children: [
                        _buildCompanyCard(),

                        const SizedBox(
                          height: 24,
                        ),

                        _buildLoginCard(),

                        const SizedBox(
                          height: 30,
                        ),

                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (_isLoggingIn)
              Positioned.fill(
                child:
                    _buildProcessingOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      color: pageBackground,

      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,

            child: Container(
              width: 280,
              height: 280,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: sciBlue.withValues(
                  alpha: 0.04,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -140,
            left: -120,

            child: Container(
              width: 330,
              height: 330,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: sciGreen.withValues(
                  alpha: 0.035,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        22,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color:
              const Color(0xFFE3EBF0),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),

            blurRadius: 20,

            offset:
                const Offset(0, 7),
          ),
        ],
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          SizedBox(
            width: 260,
            height: 105,

            child: Image.asset(
              'assets/images/stride_logo.png',

              fit: BoxFit.contain,

              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                debugPrint(
                  'SCiRIDER: Logo error: $error',
                );

                return Image.asset(
                  'assets/images/stride_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_rounded,
                          size: 58,
                          color: sciBlue,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'STRIDE',
                          style: TextStyle(
                            color: sciNavy,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Container(
            width: 55,
            height: 4,

            decoration: BoxDecoration(
              color: sciBlue,

              borderRadius:
                  BorderRadius.circular(20),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          const Text(
            'SCiRIDER',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: sciNavy,
              fontSize: 30,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Secure  •  Reliable  •  Efficient',

            textAlign: TextAlign.center,

            style: TextStyle(
              color:
                  Color(0xFF526C80),

              fontSize: 13,

              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.fromLTRB(
        22,
        24,
        22,
        25,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color:
              const Color(0xFFE3EBF0),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),

            blurRadius: 20,

            offset:
                const Offset(0, 7),
          ),
        ],
      ),

      child: Form(
        key: _formKey,

        child: Column(
          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Welcome Back',

              style: TextStyle(
                color:
                    Color(0xFF162D3D),

                fontSize: 25,

                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Login to continue to SCiRIDER',

              style: TextStyle(
                color: secondaryText,

                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 26,
            ),

            _buildFieldLabel(
              'Username',
            ),

            const SizedBox(
              height: 8,
            ),

            _buildLoginField(),

            const SizedBox(
              height: 20,
            ),

            _buildFieldLabel(
              'Password',
            ),

            const SizedBox(
              height: 8,
            ),

            _buildPasswordField(),

            const SizedBox(
              height: 14,
            ),

            _buildRememberForgot(),

            const SizedBox(
              height: 22,
            ),

            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(
    String text,
  ) {
    return Text(
      text,

      style: const TextStyle(
        color:
            Color(0xFF253846),

        fontSize: 13,

        fontWeight:
            FontWeight.w700,
      ),
    );
  }

  Widget _buildLoginField() {
    return TextFormField(
      controller:
          _loginIdController,

      focusNode:
          _loginFocusNode,

      enabled:
          !_isLoggingIn,

      textInputAction:
          TextInputAction.next,

      autofillHints: const [
        AutofillHints.username,
      ],

      onFieldSubmitted: (_) {
        _passwordFocusNode
            .requestFocus();
      },

      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please enter username';
        }

        return null;
      },

      decoration:
          _fieldDecoration(
        hint: 'Enter username',

        icon:
            Icons.person_outline_rounded,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller:
          _passwordController,

      focusNode:
          _passwordFocusNode,

      enabled:
          !_isLoggingIn,

      obscureText:
          _obscurePassword,

      textInputAction:
          TextInputAction.done,

      autofillHints: const [
        AutofillHints.password,
      ],

      onFieldSubmitted: (_) {
        _login();
      },

      validator: (value) {
        if (value == null ||
            value.isEmpty) {
          return 'Please enter password';
        }

        return null;
      },

      decoration:
          _fieldDecoration(
        hint: 'Enter password',

        icon:
            Icons.lock_outline_rounded,

        suffix: IconButton(
          onPressed:
              _isLoggingIn
                  ? null
                  : () {
                      setState(() {
                        _obscurePassword =
                            !_obscurePassword;
                      });
                    },

          icon: Icon(
            _obscurePassword
                ? Icons
                    .visibility_outlined
                : Icons
                    .visibility_off_outlined,

            color:
                const Color(
              0xFF7E909C,
            ),

            size: 22,
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle:
          const TextStyle(
        color:
            Color(0xFFA0ADB6),

        fontSize: 14,
      ),

      prefixIcon: Icon(
        icon,

        size: 21,

        color:
            const Color(
          0xFF7D909C,
        ),
      ),

      suffixIcon: suffix,

      filled: true,

      fillColor:
          fieldBackground,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 17,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(11),

        borderSide:
            const BorderSide(
          color: fieldBorder,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(11),

        borderSide:
            const BorderSide(
          color: sciBlue,
          width: 1.5,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(11),

        borderSide:
            const BorderSide(
          color: Colors.redAccent,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(11),

        borderSide:
            const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildRememberForgot() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,

          activeColor: sciBlue,

          onChanged:
              _isLoggingIn
                  ? null
                  : (value) {
                      setState(() {
                        _rememberMe =
                            value ??
                                false;
                      });
                    },
        ),

        const Expanded(
          child: Text(
            'Remember Me',

            style: TextStyle(
              color: secondaryText,

              fontSize: 13,
            ),
          ),
        ),

        TextButton(
          onPressed:
              _isLoggingIn
                  ? null
                  : _forgotPassword,

          child: const Text(
            'Forgot Password?',

            style: TextStyle(
              color: sciBlue,

              fontSize: 13,

              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,

      child: ElevatedButton(
        onPressed:
            _isLoggingIn
                ? null
                : _login,

        style:
            ElevatedButton.styleFrom(
          elevation: 0,

          backgroundColor:
              sciBlue,

          foregroundColor:
              Colors.white,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
        ),

        child: _isLoggingIn
            ? const Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                children: [
                  SizedBox(
                    width: 20,
                    height: 20,

                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,

                      color:
                          Colors.white,
                    ),
                  ),

                  SizedBox(
                    width: 12,
                  ),

                  Text(
                    'Signing In...',

                    style: TextStyle(
                      fontSize: 16,

                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                children: [
                  Text(
                    'Login',

                    style: TextStyle(
                      fontSize: 16,

                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),

                  SizedBox(
                    width: 12,
                  ),

                  Icon(
                    Icons
                        .arrow_forward_rounded,

                    size: 22,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Text(
      'SCiRIDER UAT  •  Version 2.0.0',

      textAlign: TextAlign.center,

      style: TextStyle(
        color:
            Color(0xFF98A8B3),

        fontSize: 11,
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Material(
      color: Colors.white.withValues(alpha: 0.98),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 180,
                height: 80,
                child: Image.asset(
                  'assets/images/stride_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/stride_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                        Icons.business_rounded,
                        size: 58,
                        color: sciBlue,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: sciBlue,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Please wait...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: sciNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Signing in to SCiRIDER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _forgotPassword() {
    _showInfoMessage(
      'Forgot Password will be available soon.',
    );
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message.isEmpty
              ? 'Unable to login.'
              : message,
        ),

        backgroundColor:
            Colors.red.shade700,

        behavior:
            SnackBarBehavior.floating,

        duration:
            const Duration(
          seconds: 4,
        ),
      ),
    );
  }

  void _showInfoMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),

        backgroundColor:
            sciNavy,

        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}