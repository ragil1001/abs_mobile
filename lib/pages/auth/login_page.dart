// lib/presentation/pages/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();

    // Setup animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
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
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      if (success) {
        CustomSnackbar.showSuccess(
          context,
          'Selamat datang kembali! Login berhasil.',
        );

        // Fade out animation sebelum navigate
        await _fadeController.reverse();
        if (!mounted) return;

        // Navigate ke home
        Navigator.pushReplacementNamed(context, '/home');

        // Wait for home page to fully load
        await Future.delayed(const Duration(milliseconds: 500));

        // Mark app as ready dan process pending notification
        FirebaseMessagingService.markAppReady();

        // Check and process pending notification
        if (FirebaseMessagingService.hasPendingNotification()) {
          print('📱 Processing pending notification after login...');
          await FirebaseMessagingService.processPendingNotification();
        }
      } else {
        CustomSnackbar.showError(
          context,
          authProvider.errorMessage ??
              'Username atau password yang Anda masukkan salah. Silakan coba lagi.',
        );
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
      body: Consumer<AuthProvider>(
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
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(screenWidth * 0.12),
                            bottomRight: Radius.circular(screenWidth * 0.12),
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
                            // Logo Perusahaan
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
                              padding: EdgeInsets.only(top: screenWidth * 0.03),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
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

                            // Nama Perusahaan
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

                            // Subtitle
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
                              // Welcome Text
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
                                enabled: !authProvider.isLoading,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
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
                                enabled: !authProvider.isLoading,
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
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
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
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
                                onTap: authProvider.isLoading
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
                                        onChanged: authProvider.isLoading
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  _rememberMe = value ?? false;
                                                });
                                              },
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
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
                                onTap: authProvider.isLoading ? null : _login,
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.019,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: authProvider.isLoading
                                        ? LinearGradient(
                                            colors: [
                                              AppColors.grey,
                                              AppColors.grey.withOpacity(0.8),
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
                                    boxShadow: authProvider.isLoading
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
                                  child: authProvider.isLoading
                                      ? const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppColors.white,
                                                  ),
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

                              // Footer
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
    );
  }
}
