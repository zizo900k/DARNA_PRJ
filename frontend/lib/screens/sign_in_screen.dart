import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import '../theme/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart' as google_auth;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/google_sign_in_button/google_sign_in_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String _email = '';
  String _password = '';
  StreamSubscription? _googleSignInSubscription;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _googleSignInSubscription = google_auth.GoogleSignIn.instance.authenticationEvents.listen((event) async {
        if (event is google_auth.GoogleSignInAuthenticationEventSignIn) {
          try {
            final auth = event.user.authentication; // synchronous on web stream
            if (auth is Future) {
               final authResolved = await auth;
               _processToken(authResolved.idToken);
            } else {
               _processToken((auth as dynamic).idToken);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e'), backgroundColor: Colors.redAccent));
            }
          }
        }
      });
    }
  }

  Future<void> _processToken(String? idToken) async {
    if (idToken != null) {
      final response = await ApiService.post('/auth/google', body: {'id_token': idToken}, requiresAuth: false);
      if (!mounted) return;
      await context.read<AuthProvider>().handleGoogleSignInResponse(response);
      if (mounted) {
        if (context.read<AuthProvider>().user?['role'] == 'admin') {
          context.go('/admin/shell');
        } else {
          context.go('/home');
        }
      }
    }
  }

  @override
  void dispose() {
    _googleSignInSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    bool isLoading = true;
    setState(() => isLoading = true);
    try {
      await context.read<AuthProvider>().login(_email, _password);
      if (mounted) {
        if (context.read<AuthProvider>().user?['role'] == 'admin') {
          context.go('/admin/shell');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
      // ignore: unused_local_variable
      isLoading;
    }
  }

  Future<void> _handleGoogleSignIn() async {
    bool isLoading = true;
    setState(() => isLoading = true);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
      if (mounted) {
        if (context.read<AuthProvider>().user?['role'] == 'admin') {
          context.go('/admin/shell');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
      // ignore: unused_local_variable
      isLoading;
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical:
                      isSmallDevice ? screenHeight * 0.03 : screenHeight * 0.05,
                ),
                child: Column(
                  children: [
                    // Language Toggle Button
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: languageProvider.locale.languageCode,
                              icon: Icon(Icons.keyboard_arrow_down, color: theme.textTheme.bodyLarge?.color),
                              dropdownColor: theme.scaffoldBackgroundColor,
                              style: TextStyle(
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  languageProvider.setLanguage(newValue);
                                }
                              },
                              items: const [
                                DropdownMenuItem(value: 'en', child: Text('English')),
                                DropdownMenuItem(value: 'fr', child: Text('Français')),
                                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Logo
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: isSmallDevice
                            ? screenHeight * 0.03
                            : screenHeight * 0.04,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: isSmallDevice
                                ? screenWidth * 0.25
                                : screenWidth * 0.30,
                            height: isSmallDevice
                                ? screenWidth * 0.25
                                : screenWidth * 0.30,
                            margin:
                                EdgeInsets.only(bottom: screenHeight * 0.015),
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
                          const SizedBox(height: 4),
                          Text(
                            context.tr('welcome_subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                      child: Column(
                        children: [
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
                            placeholder: context.tr('password'),
                            value: _password,
                            onChangeText: (val) =>
                                setState(() => _password = val),
                            secureTextEntry: true,
                            icon: Icons.lock_outline,
                            margin: const EdgeInsets.only(bottom: 16),
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding:
                                  EdgeInsets.only(bottom: screenHeight * 0.02),
                              child: TextButton(
                                onPressed: () => context.push('/forgot-password'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  context.tr('forgot_password'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          CustomButton(
                            title: context.tr('signin'),
                            onPress: _handleSignIn,
                            margin:
                                EdgeInsets.only(bottom: screenHeight * 0.02),
                          ),

                          // Social Login Divider
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.02),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: isDark
                                            ? DarkColors.border
                                            : LightColors.border)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    context.tr('or'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme.bodyMedium?.color,
                                      fontWeight: FontWeight.w500,
                                    ),
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

                          // Social Login Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
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
                                    size: 32,
                                    isDark: isDark,
                                    onTap: () {
                                      if (!kIsWeb) _handleGoogleSignIn();
                                    },
                                  ),
                                  if (kIsWeb)
                                    Positioned.fill(
                                      child: Opacity(
                                        opacity: 0.01,
                                        child: buildGoogleSignInWebButton(),
                                      ),
                                    ),
                                ],
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
                                size: 32,
                                isDark: isDark,
                                onTap: _showComingSoon,
                              ),
                              const SizedBox(width: 16),
                              _SocialButton(
                                icon: Icons.apple,
                                color: isDark ? Colors.white : Colors.black,
                                size: 24,
                                isDark: isDark,
                                onTap: _showComingSoon,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Footer
                    Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.02),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr('dont_have_account'),
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.go('/signup');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              context.tr('signup'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Browse as Guest
                    Padding(
                      padding: EdgeInsets.only(
                          top: screenHeight * 0.01,
                          bottom: screenHeight * 0.02),
                      child: TextButton(
                        onPressed: () => context.go('/home_guest'),
                        child: Text(
                          context.tr('browse_as_guest'),
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData? icon;
  final Widget? customIcon;
  final Color? color;
  final double size;
  final bool isDark;
  final VoidCallback onTap;

  const _SocialButton({
    this.icon,
    this.customIcon,
    this.color,
    required this.size,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isDark
            ? DarkColors.backgroundSecondary
            : LightColors.backgroundSecondary,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? DarkColors.border : LightColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: customIcon ??
                Icon(
                  icon,
                  color: color,
                  size: size,
                ),
          ),
        ),
      ),
    );
  }
}

