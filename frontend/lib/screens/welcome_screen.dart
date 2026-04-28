import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/language_provider.dart';
import '../theme/auth_provider.dart';
import '../widgets/custom_button.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _hasRedirected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tryRedirect();
  }

  void _tryRedirect() {
    if (_hasRedirected) return;
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoading && authProvider.isLoggedIn) {
      _hasRedirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (authProvider.user?['role'] == 'admin') {
            context.go('/admin/shell');
          } else {
            context.go('/home');
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (authProvider.isLoggedIn) {
      // Redirect is already scheduled by didChangeDependencies
      return const Scaffold(backgroundColor: Colors.black);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallDevice = screenWidth < 380;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          CachedNetworkImage(
            imageUrl:
                'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800',
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
                const Center(child: Icon(Icons.error)),
          ),

          // Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black45,
                  Colors.black87,
                  Colors.black,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical:
                      isSmallDevice ? screenHeight * 0.03 : screenHeight * 0.05,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Consumer<LanguageProvider>(
                      builder: (context, languageProvider, _) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Language Toggle Button
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.3),
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
                                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                            dropdownColor: Colors.black87,
                                            style: const TextStyle(
                                              color: Colors.white,
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
                                  // Logo and Branding
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: isSmallDevice
                                            ? screenWidth * 0.35
                                            : screenWidth * 0.40,
                                        height: isSmallDevice
                                            ? screenWidth * 0.35
                                            : screenWidth * 0.40,
                                        margin: EdgeInsets.only(
                                            bottom: screenHeight * 0.03),
                                        child: Image.asset(
                                          'assets/logo.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      const Text(
                                        'Darna',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -1,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              offset: Offset(0, 2),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Find Your Dream Home'.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withValues(alpha: 0.9),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                      height: screenHeight *
                                          0.05), // Added spacing instead of Expanded

                                  // Bottom Content
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                            bottom: screenHeight * 0.03),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              context.tr('welcome'),
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            SizedBox(
                                                height: screenHeight * 0.015),
                                            Text(
                                              context.tr('welcome_subtitle'),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.white
                                                    .withValues(alpha: 0.85),
                                                height: 1.4,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      CustomButton(
                                        title: context.tr('get_started'),
                                        margin: EdgeInsets.only(
                                            bottom: screenHeight * 0.015),
                                        onPress: () {
                                          context.push('/signin');
                                        },
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            context.push('/home_guest'),
                                        child: Text(
                                          context.tr('browse_as_guest'),
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                            fontWeight: FontWeight.w500,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Colors.white
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.015),
                                      Column(
                                        children: [
                                          Text(
                                            'Made with â‌¤ï¸ڈ in Morocco',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color:
                                                  Colors.white.withValues(alpha: 0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Version 1.0',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  Colors.white.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

