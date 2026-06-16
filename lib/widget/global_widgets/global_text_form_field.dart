import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_color/app_color.dart';

class GlobalTextFormField extends StatefulWidget {
  const GlobalTextFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixWidget,
    this.validator,
    this.onSaved,
    this.isPassword = false,
    this.keyboardType,
    this.onChanged,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.onTap,
    this.borderSide,
    this.focusedBorderSide,
    this.borderRadius = 12.0,
    this.fillColor,
    this.isRequired = false,
    this.showCounter = false,
    this.maxLength,
    this.enableSuggestions = true,
    this.backgroundColor,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? suffixWidget;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final bool isPassword;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final GestureTapCallback? onTap;
  final BorderSide? borderSide;
  final BorderSide? focusedBorderSide;
  final double borderRadius;
  final Color? fillColor;
  final bool isRequired;
  final bool showCounter;
  final int? maxLength;
  final bool enableSuggestions;
  final Color? backgroundColor;

  @override
  State<GlobalTextFormField> createState() => _GlobalTextFormFieldState();
}

class _GlobalTextFormFieldState extends State<GlobalTextFormField> {
  late bool _obscureText;
  late FocusNode _focusNode;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultBorderSide = widget.borderSide ??
        BorderSide(
          color: _isFocused
              ? AppColors.primaryLight
              : (_isHovered
              ? AppColors.primaryLight.withOpacity(0.5)
              : Colors.grey.shade200),
          width: _isFocused ? 1.5 : 1,
        );

    final defaultFocusedBorderSide = widget.focusedBorderSide ??
        const BorderSide(color: AppColors.primaryLight, width: 1.5);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.labelText != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Text(
                    widget.labelText!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isFocused
                          ? AppColors.primaryLight
                          : Colors.grey.shade700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (widget.isRequired) ...[
                    const SizedBox(width: 4),
                    Text(
                      '*',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? widget.fillColor ?? Colors.white,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: _isFocused
                  ? [
                BoxShadow(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              obscureText: _obscureText,
              onChanged: widget.onChanged,
              validator: widget.validator,
              onSaved: widget.onSaved,
              textInputAction: widget.textInputAction,
              onFieldSubmitted: widget.onFieldSubmitted,
              autofocus: widget.autofocus,
              textCapitalization: widget.textCapitalization,
              inputFormatters: widget.inputFormatters,
              textAlign: widget.textAlign,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              readOnly: widget.readOnly,
              onTap: widget.onTap,
              enableSuggestions: widget.enableSuggestions,
              maxLength: widget.maxLength,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.grey.shade900,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              decoration: InputDecoration(
                floatingLabelBehavior: FloatingLabelBehavior.never,
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: widget.fillColor ?? Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: defaultBorderSide,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: defaultBorderSide,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: defaultFocusedBorderSide,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                    width: 1.5,
                  ),
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: widget.prefixIcon,
                )
                    : null,
                suffixIcon: widget.isPassword
                    ? IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      key: ValueKey(_obscureText),
                      color: _isFocused
                          ? AppColors.primaryLight
                          : Colors.grey.shade500,
                      size: 20,
                    ),
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
                    : widget.suffixIcon != null
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: widget.suffixIcon,
                )
                    : null,
                suffix: widget.suffixWidget,
                counterText: widget.showCounter && widget.maxLength != null
                    ? null
                    : '',
                counterStyle: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
                errorStyle: const TextStyle(
                  fontSize: 11,
                  height: 0.8,
                ),
              ),
            ),
          ),
          if (widget.showCounter && widget.maxLength != null && widget.controller != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${widget.controller?.text.length ?? 0}/${widget.maxLength}',
                  style: TextStyle(
                    fontSize: 11,
                    color: (widget.controller?.text.length ?? 0) >= (widget.maxLength ?? 0)
                        ? Colors.red.shade400
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}