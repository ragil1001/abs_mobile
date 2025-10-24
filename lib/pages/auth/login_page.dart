// lib/presentation/pages/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../components/custom_snackbar.dart';
import '../../../data/services/firebase_messaging_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isProcessing = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadRememberedCredentials() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = await authProvider.getRememberedUsername();
    final shouldRemember = await authProvider.shouldRemember();

    if (username != null && shouldRemember) {
      setState(() {
        _usernameController.text = username;
        _rememberMe = shouldRemember;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      _loadingController.forward();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      if (success) {
        // Get user name untuk welcome message
        final userName =
            authProvider.currentUser?.nama.split(' ').first ?? 'User';

        // Tunggu sebentar untuk transisi yang smooth
        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        // Fade out semua
        await Future.wait([
          _fadeController.reverse(),
          _loadingController.reverse(),
        ]);

        if (!mounted) return;

        // Navigate ke home dan langsung show snackbar
        Navigator.pushReplacementNamed(context, '/home');

        // Mark app ready dan process notification
        Future.delayed(const Duration(milliseconds: 500), () {
          FirebaseMessagingService.markAppReady();
          if (FirebaseMessagingService.hasPendingNotification()) {
            FirebaseMessagingService.processPendingNotification();
          }
        });
      } else {
        await _loadingController.reverse();

        if (!mounted) return;

        setState(() {
          _isProcessing = false;
        });

        final errorMessage = authProvider.errorMessage;
        final errorType = authProvider.errorType;

        if (errorType == 'timeout' || errorType == 'connection_error') {
          CustomSnackbar.showWarning(
            context,
            errorMessage ?? 'Terjadi masalah koneksi. Silakan coba lagi.',
          );
        } else if (errorType == 'server_error') {
          CustomSnackbar.showError(
            context,
            errorMessage ??
                'Server sedang mengalami gangguan. Silakan coba lagi nanti.',
          );
        } else {
          CustomSnackbar.showError(
            context,
            errorMessage ??
                'Login gagal. Silakan periksa username dan password Anda.',
          );
        }

        authProvider.clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Main Content
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          // Header dengan Gradient
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(
                              padding,
                              screenHeight * 0.08,
                              padding,
                              screenHeight * 0.05,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(screenWidth * 0.12),
                                bottomRight: Radius.circular(
                                  screenWidth * 0.12,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: screenWidth * 0.24,
                                  height: screenWidth * 0.24,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.only(
                                    top: screenWidth * 0.03,
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.business_rounded,
                                              size: screenWidth * 0.13,
                                              color: AppColors.primary,
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Text(
                                  AppStrings.companyName,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.052,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.006),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                    vertical: screenHeight * 0.006,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "Sistem Presensi Karyawan",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.034,
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Form Section
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              padding,
                              screenHeight * 0.04,
                              padding,
                              screenHeight * 0.03,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.loginTitle,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.065,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.004),
                                  Text(
                                    AppStrings.loginSubtitle,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.036,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.035),

                                  // Username Field
                                  Text(
                                    AppStrings.username,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.036,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.008),
                                  TextFormField(
                                    controller: _usernameController,
                                    focusNode: _usernameFocus,
                                    enabled: !_isProcessing,
                                    keyboardType: TextInputType.text,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(
                                        context,
                                      ).requestFocus(_passwordFocus);
                                    },
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.038,
                                      color: AppColors.black,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "Masukkan username",
                                      hintStyle: TextStyle(
                                        color: Colors.black26,
                                        fontSize: screenWidth * 0.036,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.person_outline,
                                        color: AppColors.primary,
                                        size: screenWidth * 0.056,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F8F8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.error,
                                          width: 1,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.error,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.04,
                                        vertical: screenHeight * 0.018,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppStrings.usernameRequired;
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: screenHeight * 0.022),

                                  // Password Field
                                  Text(
                                    AppStrings.password,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.036,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.008),
                                  TextFormField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocus,
                                    obscureText: _obscurePassword,
                                    enabled: !_isProcessing,
                                    keyboardType: TextInputType.visiblePassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onFieldSubmitted: (_) => _login(),
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.038,
                                      color: AppColors.black,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "Masukkan password",
                                      hintStyle: TextStyle(
                                        color: Colors.black26,
                                        fontSize: screenWidth * 0.036,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: AppColors.primary,
                                        size: screenWidth * 0.056,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.black38,
                                          size: screenWidth * 0.052,
                                        ),
                                        onPressed: _isProcessing
                                            ? null
                                            : () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F8F8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.error,
                                          width: 1,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.error,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.04,
                                        vertical: screenHeight * 0.018,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppStrings.passwordRequired;
                                      }
                                      if (value.length < 6) {
                                        return AppStrings.passwordMinLength;
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: screenHeight * 0.012),

                                  // Remember Me
                                  GestureDetector(
                                    onTap: _isProcessing
                                        ? null
                                        : () {
                                            setState(() {
                                              _rememberMe = !_rememberMe;
                                            });
                                          },
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: screenWidth * 0.048,
                                          height: screenWidth * 0.048,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: _isProcessing
                                                ? null
                                                : (value) {
                                                    setState(() {
                                                      _rememberMe =
                                                          value ?? false;
                                                    });
                                                  },
                                            activeColor: AppColors.primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.02),
                                        Text(
                                          AppStrings.rememberMe,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.034,
                                            color: AppColors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: screenHeight * 0.035),

                                  // Login Button
                                  GestureDetector(
                                    onTap: _isProcessing ? null : _login,
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        vertical: screenHeight * 0.019,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: _isProcessing
                                            ? LinearGradient(
                                                colors: [
                                                  AppColors.grey,
                                                  AppColors.grey.withOpacity(
                                                    0.8,
                                                  ),
                                                ],
                                              )
                                            : const LinearGradient(
                                                colors: [
                                                  AppColors.primary,
                                                  AppColors.primaryDark,
                                                ],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: _isProcessing
                                            ? []
                                            : [
                                                BoxShadow(
                                                  color: AppColors.primary
                                                      .withOpacity(0.3),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                      ),
                                      child: _isProcessing
                                          ? const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(AppColors.white),
                                                ),
                                              ),
                                            )
                                          : Text(
                                              AppStrings.login,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.white,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                    ),
                                  ),

                                  SizedBox(height: screenHeight * 0.04),

                                  Center(
                                    child: Text(
                                      "© 2025 ${AppStrings.companyName}",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        color: Colors.black38,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Loading Overlay
          if (_isProcessing)
            FadeTransition(
              opacity: _loadingController,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Memproses login...',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mohon tunggu sebentar',
                          style: TextStyle(
                            fontSize: screenWidth * 0.034,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
