import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/jot_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/encryption_provider.dart';
import '../../providers/jots_provider.dart';
import '../home/_ai_search_widgets.dart' show SttMixin;

class WidgetJotComposeScreen extends ConsumerStatefulWidget {
  const WidgetJotComposeScreen({super.key});

  @override
  ConsumerState<WidgetJotComposeScreen> createState() =>
      _WidgetJotComposeScreenState();
}

class _WidgetJotComposeScreenState extends ConsumerState<WidgetJotComposeScreen>
    with SttMixin<WidgetJotComposeScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _keyboardTimers = <Timer>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    initStt();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureKeyLoaded();
      _showKeyboard();
    });
  }

  @override
  void dispose() {
    for (final timer in _keyboardTimers) {
      timer.cancel();
    }
    stopStt();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _ensureKeyLoaded() async {
    if (!mounted) return;
    if (ref.read(aesKeyProvider) != null) return;
    final key = await ref.read(encryptionServiceProvider).loadKey();
    if (key != null && mounted) {
      ref.read(aesKeyProvider.notifier).state = key;
    }
  }

  void _showKeyboard() {
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_focusNode);
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    _keyboardTimers.add(Timer(const Duration(milliseconds: 250), () {
      if (!mounted || _focusNode.hasFocus) return;
      FocusScope.of(context).requestFocus(_focusNode);
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    }));
    _keyboardTimers.add(Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_focusNode);
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    }));
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    var repo = ref.read(jotRepositoryProvider);
    if (repo == null) {
      await _ensureKeyLoaded();
      if (!mounted) return;
      repo = ref.read(jotRepositoryProvider);
    }
    if (repo == null) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).jotSaveUnavailable)),
      );
      return;
    }
    await repo.createJot(text: text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).jotSavedSnack)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) SystemNavigator.pop();
  }

  void _onSttResult(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final insertText = '$trimmed ';
    final sel = _controller.selection;
    final raw = _controller.text;
    if (sel.isValid) {
      final start = sel.start.clamp(0, raw.length);
      final end = sel.end.clamp(0, raw.length);
      final next = raw.replaceRange(start, end, insertText);
      _controller.value = _controller.value.copyWith(
        text: next,
        selection: TextSelection.collapsed(offset: start + insertText.length),
      );
    } else {
      _controller.text = raw.isEmpty ? trimmed : '$raw $trimmed';
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l = AppStrings.of(context);
    final count = _controller.text.length;
    final showCounter = count >= JotConstants.showCounterAtChars;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _saving ? null : () => SystemNavigator.pop(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: GestureDetector(
              onTap: () {},
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              l.jotAddDialogTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close),
                              onPressed:
                                  _saving ? null : () => SystemNavigator.pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          enabled: !_saving,
                          maxLength: JotConstants.maxChars,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          minLines: 1,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                              JotConstants.maxChars,
                            ),
                          ],
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: l.jotInputHint,
                            border: const OutlineInputBorder(),
                            counterText: '',
                            suffixIcon: sttAvailable
                                ? IconButton(
                                    tooltip: listening
                                        ? l.editorSttStop
                                        : l.editorSttRecord,
                                    icon: Icon(
                                        listening ? Icons.mic : Icons.mic_none),
                                    color: listening ? cs.error : null,
                                    onPressed: _saving
                                        ? null
                                        : () => toggleListen(_onSttResult),
                                  )
                                : null,
                          ),
                          onSubmitted: (_) => _save(),
                        ),
                        if (showCounter)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l.jotCharCounter(count, JotConstants.maxChars),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: count >= JotConstants.maxChars
                                      ? cs.error
                                      : cs.outline,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(l.actionSave),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
