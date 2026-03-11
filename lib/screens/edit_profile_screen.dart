import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import '../theme/theme_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _googleLinked = true;
  bool _facebookLinked = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Mohamed Ez-zidany');
    _phoneController = TextEditingController(text: '+212 624424544');
    _emailController = TextEditingController(text: 'zidanim@email.com');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleUpdate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('profile_updated')),
        backgroundColor: AppColors.primary,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.chevron_left, size: 28, color: theme.textTheme.bodyLarge?.color),
                    ),
                  ),
                  Text(
                    context.tr('edit_profile'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    // Avatar
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: 'https://i.pravatar.cc/150?img=60',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 3,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.camera_alt, size: 18, color: AppColors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form Fields
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputField(
                            controller: _nameController,
                            placeholder: context.tr('full_name'),
                            icon: Icons.person_outline,
                            theme: theme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          _buildInputField(
                            controller: _phoneController,
                            placeholder: context.tr('phone'),
                            icon: Icons.call_outlined,
                            keyboardType: TextInputType.phone,
                            theme: theme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          _buildInputField(
                            controller: _emailController,
                            placeholder: context.tr('email'),
                            icon: Icons.mail_outlined,
                            keyboardType: TextInputType.emailAddress,
                            theme: theme,
                            isDark: isDark,
                          ),
                          
                          const SizedBox(height: 32),

                          // APP SETTINGS SECTION
                          Text(
                            context.tr('settings'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildPrefItem(
                            icon: Icons.language,
                            title: context.tr('language'),
                            trailing: _buildLanguagePicker(context),
                            theme: theme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildPrefItem(
                            icon: isDark ? Icons.dark_mode : Icons.light_mode,
                            title: isDark ? context.tr('dark_mode') : context.tr('light_mode'),
                            trailing: Switch(
                              value: isDark,
                              onChanged: (val) {
                                context.read<ThemeProvider>().toggleTheme();
                              },
                              activeColor: AppColors.primary,
                            ),
                            theme: theme,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 32),

                          Text(
                            context.tr('social_accounts'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              _buildSocialButton(
                                customIcon: SvgPicture.string(
                                  '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.7 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  <path fill="none" d="M0 0h48v48H0z"/>
</svg>''',
                                  width: 24,
                                  height: 24,
                                ),
                                text: _googleLinked ? context.tr('unlink') : context.tr('link'),
                                isLinked: _googleLinked,
                                onTap: () => setState(() => _googleLinked = !_googleLinked),
                                theme: theme,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 16),
                              _buildSocialButton(
                                customIcon: SvgPicture.string(
                                  '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path fill="#1877F2" d="M504 256C504 119 393 8 256 8S8 119 8 256c0 123.78 90.69 226.38 209.25 245V327.69h-63V256h63v-54.64c0-62.15 37-96.48 93.67-96.48 27.14 0 55.52 4.84 55.52 4.84v61h-31.28c-30.8 0-40.41 19.12-40.41 38.73V256h68.78l-11 71.69h-57.78V501C413.31 482.38 504 379.78 504 256z"/>
</svg>''',
                                  width: 24,
                                  height: 24,
                                ),
                                text: _facebookLinked ? context.tr('unlink') : context.tr('link'),
                                isLinked: _facebookLinked,
                                onTap: () => setState(() => _facebookLinked = !_facebookLinked),
                                theme: theme,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? DarkColors.border : LightColors.border,
                    width: 1,
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: _handleUpdate,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF16A085)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    context.tr('update'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? DarkColors.border : LightColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 16,
          color: theme.textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: InputBorder.none,
          suffixIcon: Icon(icon, color: theme.textTheme.bodyMedium?.color, size: 20),
        ),
      ),
    );
  }

  Widget _buildPrefItem({
    required IconData icon,
    required String title,
    required Widget trailing,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? DarkColors.border : LightColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildLanguagePicker(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    return DropdownButton<String>(
      value: languageProvider.locale.languageCode,
      underline: const SizedBox(),
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
      onChanged: (String? newValue) {
        if (newValue != null) {
          languageProvider.setLanguage(newValue);
        }
      },
      items: const [
        DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontSize: 14))),
        DropdownMenuItem(value: 'fr', child: Text('Français', style: TextStyle(fontSize: 14))),
        DropdownMenuItem(value: 'ar', child: Text('العربية', style: TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _buildSocialButton({
    Widget? customIcon,
    required String text,
    required bool isLinked,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isLinked
                ? (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLinked ? AppColors.primary : (isDark ? DarkColors.border : LightColors.border),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (customIcon != null) customIcon,
              const SizedBox(width: 10),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isLinked ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
