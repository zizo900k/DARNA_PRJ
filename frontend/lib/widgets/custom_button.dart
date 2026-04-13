import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ButtonVariant { primary, outline }

class CustomButton extends StatefulWidget {
  final String title;
  final VoidCallback? onPress;
  final bool loading;
  final ButtonVariant variant;
  final bool disabled;
  final EdgeInsetsGeometry? margin;

  const CustomButton({
    super.key,
    required this.title,
    this.onPress,
    this.loading = false,
    this.variant = ButtonVariant.primary,
    this.disabled = false,
    this.margin,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled =
        widget.disabled || widget.loading || widget.onPress == null;

    final Widget child = widget.loading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.variant == ButtonVariant.outline
                    ? AppColors.primary
                    : AppColors.white,
              ),
            ),
          )
        : Text(
            widget.title,
            style: TextStyle(
              color: widget.variant == ButtonVariant.outline
                  ? AppColors.primary
                  : AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          );

    final BoxDecoration decoration = widget.variant == ButtonVariant.outline
        ? BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 2),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isDisabled
                  ? [const Color(0xFF7A8B99), const Color(0xFFB0BCC5)]
                  : [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      offset: const Offset(0, 8),
                      blurRadius: 16,
                    ),
                  ],
          );

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: Semantics(
        button: true,
        label: widget.title,
        enabled: !isDisabled,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : widget.onPress,
              onTapDown: isDisabled
                  ? null
                  : (_) => setState(() => _isPressed = true),
              onTapUp: isDisabled
                  ? null
                  : (_) => setState(() => _isPressed = false),
              onTapCancel: isDisabled
                  ? null
                  : () => setState(() => _isPressed = false),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: decoration,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Center(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

