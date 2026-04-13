import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:confetti/confetti.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import 'package:provider/provider.dart';
import '../theme/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_fullName.isEmpty || _email.isEmpty || _password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('fill_required_fields'))),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await context.read<AuthProvider>().register(
        _fullName,
        _email,
        _password,
        phone: _phone.isNotEmpty ? _phone : null,
      );
      
      if (mounted) {
        Navigator.pop(context); // Dismiss loading overlay
        _confettiController.play();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.primary, size: 80),
                const SizedBox(height: 24),
                Text(
                  context.tr('account_created'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('welcome_darna'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  title: context.tr('get_started'),
                  onPress: () {
                    Navigator.pop(context);
                    context.go('/home');
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading overlay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('coming_soon')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallDevice = screenWidth < 380;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical:
                    isSmallDevice ? screenHeight * 0.03 : screenHeight * 0.05,
              ),
              child: Column(
                children: [
                  // Logo/Header
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.03),
                    child: Column(
                      children: [
                        Container(
                          width: isSmallDevice
                              ? screenWidth * 0.25
                              : screenWidth * 0.30,
                          height: isSmallDevice
                              ? screenWidth * 0.25
                              : screenWidth * 0.30,
                          margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        Text(
                          'Darna',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('create_account'),
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  CustomInput(
                    placeholder: context.tr('full_name'),
                    value: _fullName,
                    onChangeText: (val) => setState(() => _fullName = val),
                    icon: Icons.person_outline,
                    margin: const EdgeInsets.only(bottom: 16),
                  ),

                  CustomInput(
                    placeholder: context.tr('email'),
                    value: _email,
                    onChangeText: (val) => setState(() => _email = val),
                    keyboardType: TextInputType.emailAddress,
                    autoCapitalize: TextCapitalization.none,
                    icon: Icons.mail_outline,
                    margin: const EdgeInsets.only(bottom: 16),
                  ),

                  CustomInput(
                    placeholder: context.tr('phone'),
                    value: _phone,
                    onChangeText: (val) => setState(() => _phone = val),
                    keyboardType: TextInputType.phone,
                    icon: Icons.call_outlined,
                    margin: const EdgeInsets.only(bottom: 16),
                  ),

                  CustomInput(
                    placeholder: context.tr('password'),
                    value: _password,
                    onChangeText: (val) => setState(() => _password = val),
                    secureTextEntry: true,
                    icon: Icons.lock_outline,
                    margin: const EdgeInsets.only(bottom: 24),
                  ),

                  CustomButton(
                    title: context.tr('signup'),
                    onPress: _handleSignUp,
                    margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                  ),

                  // Social Divider
                  Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    child: Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: isDark
                                    ? DarkColors.border
                                    : LightColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            context.tr('or'),
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodyMedium?.color),
                          ),
                        ),
                        Expanded(
                            child: Divider(
                                color: isDark
                                    ? DarkColors.border
                                    : LightColors.border)),
                      ],
                    ),
                  ),

                  // Social Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(
                        customIcon: SvgPicture.string(
                          '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.7 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  <path fill="none" d="M0 0h48v48H0z"/>
</svg>''',
                          width: 26,
                          height: 26,
                        ),
                        onTap: _showComingSoon,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      _SocialButton(
                        customIcon: SvgPicture.string(
                          '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path fill="#1877F2" d="M504 256C504 119 393 8 256 8S8 119 8 256c0 123.78 90.69 226.38 209.25 245V327.69h-63V256h63v-54.64c0-62.15 37-96.48 93.67-96.48 27.14 0 55.52 4.84 55.52 4.84v61h-31.28c-30.8 0-40.41 19.12-40.41 38.73V256h68.78l-11 71.69h-57.78V501C413.31 482.38 504 379.78 504 256z"/>
</svg>''',
                          width: 25,
                          height: 25,
                        ),
                        onTap: _showComingSoon,
                        isDark: isDark,
                      ),
                    ],
                  ),

                  // Footer
                  Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.04),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.tr('already_have_account'),
                          style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color),
                        ),
                        TextButton(
                          onPressed: () => context.go('/signin'),
                          child: Text(
                            context.tr('signin'),
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppColors.primary,
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget customIcon;
  final VoidCallback onTap;
  final bool isDark;

  const _SocialButton(
      {required this.customIcon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isDark
              ? DarkColors.backgroundSecondary
              : LightColors.backgroundSecondary,
          shape: BoxShape.circle,
          border: Border.all(
              color: isDark ? DarkColors.border : LightColors.border),
        ),
        child: Center(child: customIcon),
      ),
    );
  }
}

