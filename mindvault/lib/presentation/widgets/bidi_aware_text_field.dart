import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/bidi_utils.dart';

class BidiAwareTextField extends StatefulWidget {
  const BidiAwareTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.enabled,
    this.autofocus = false,
    this.style,
    this.strutStyle,
    this.decoration,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.textAlignVertical,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.keyboardType,
    this.onSubmitted,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool? enabled;
  final bool autofocus;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final InputDecoration? decoration;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<BidiAwareTextField> createState() => _BidiAwareTextFieldState();
}

class _BidiAwareTextFieldState extends State<BidiAwareTextField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant BidiAwareTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final localeDefault = Directionality.of(context);
    final value = widget.controller.value;
    final cursor = value.selection.isValid
        ? value.selection.baseOffset
        : value.text.length;
    final dir = paragraphDirectionAt(
      text: value.text,
      cursor: cursor,
      localeDefault: localeDefault,
    );

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      style: widget.style,
      strutStyle: widget.strutStyle,
      decoration: widget.decoration,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      textAlignVertical: widget.textAlignVertical,
      textCapitalization: widget.textCapitalization,
      textInputAction: widget.textInputAction,
      keyboardType: widget.keyboardType,
      onSubmitted: widget.onSubmitted,
      inputFormatters: widget.inputFormatters,
      textDirection: dir,
      textAlign: TextAlign.start,
    );
  }
}
