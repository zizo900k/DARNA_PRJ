import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../services/auth_service.dart';
import '../theme/language_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final PageController _pageController = PageController();
  
  String _email = '';
  String _code = '';
  String _password = '';
  String _confirmPassword = '';
  
  bool _isLoading = false;

  Future<void> _requestResetCode() async {
    if (_email.isEmpty || !_email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('valid_email_error'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.forgotPassword(_email);
      if (mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('code_digits_error'))),
      );
      return;
    }
    if (_password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('password_length_error'))),
      );
      return;
    }
    if (_password != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('passwords_match_error'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.resetPassword(
        email: _email,
        code: _code,
        password: _password,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('password_reset_success')), backgroundColor: Colors.green),
        );
        context.go('/signin');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('forgot_password_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_pageController.page == 1) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Step 1: Email
          _buildEmailStep(),
          // Step 2: Code and New Password
          _buildResetStep(),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('reset_password'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('reset_password_desc'),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          CustomInput(
            placeholder: context.tr('email'),
            value: _email,
            onChangeText: (val) => setState(() => _email = val),
            keyboardType: TextInputType.emailAddress,
            autoCapitalize: TextCapitalization.none,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomButton(
                  title: context.tr('send_code'),
                  onPress: _requestResetCode,
                ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('enter_code_title'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '${context.tr('code_sent_to')} $_email${context.tr('code_sent_suffix')}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          CustomInput(
            placeholder: context.tr('digit_code'),
            value: _code,
            onChangeText: (val) => setState(() => _code = val),
            keyboardType: TextInputType.number,
            icon: Icons.lock_clock_outlined,
          ),
          const SizedBox(height: 16),
          CustomInput(
            placeholder: context.tr('new_password'),
            value: _password,
            onChangeText: (val) => setState(() => _password = val),
            secureTextEntry: true,
            icon: Icons.lock_outline,
          ),
          const SizedBox(height: 16),
          CustomInput(
            placeholder: context.tr('confirm_password'),
            value: _confirmPassword,
            onChangeText: (val) => setState(() => _confirmPassword = val),
            secureTextEntry: true,
            icon: Icons.lock_outline,
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomButton(
                  title: context.tr('reset_password'),
                  onPress: _resetPassword,
                ),
        ],
      ),
    );
  }
}
