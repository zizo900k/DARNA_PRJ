import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomInput extends StatefulWidget {
  final String placeholder;
  final String value;
  final ValueChanged<String>? onChangeText;
  final bool secureTextEntry;
  final IconData? icon;
  final TextInputType keyboardType;
  final TextCapitalization autoCapitalize;
  final bool editable;
  final EdgeInsetsGeometry? margin;

  const CustomInput({
    super.key,
    required this.placeholder,
    required this.value,
    this.onChangeText,
    this.secureTextEntry = false,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.autoCapitalize = TextCapitalization.sentences,
    this.editable = true,
    this.margin,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool _isPasswordVisible = false;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void didUpdateWidget(CustomInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? DarkColors.backgroundSecondary : LightColors.card;
    final defaultBorderColor = isDark ? Colors.transparent : const Color(0xFFE2E8F0);
    final borderColor = _isFocused ? AppColors.primary : defaultBorderColor;
    final iconColor = _isFocused ? AppColors.primary : (isDark ? DarkColors.textSecondary : LightColors.textSecondary);
    final focusBgColor = isDark ? DarkColors.card : LightColors.card;

    return Container(
      margin: widget.margin,
      height: 56,
      decoration: BoxDecoration(
        color: _isFocused ? focusBgColor : bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: _isFocused ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            const SizedBox(width: 16),
            Icon(
              widget.icon,
              size: 20,
              color: iconColor,
            ),
          ] else ...[
            const SizedBox(width: 16),
          ],
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChangeText,
              obscureText: widget.secureTextEntry && !_isPasswordVisible,
              keyboardType: widget.keyboardType,
              textCapitalization: widget.autoCapitalize,
              enabled: widget.editable,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: theme.textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: TextStyle(
                  color: isDark ? DarkColors.textTertiary : LightColors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              ),
            ),
          ),
          if (widget.secureTextEntry)
            IconButton(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

