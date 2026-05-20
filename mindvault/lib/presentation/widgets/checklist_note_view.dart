import 'package:flutter/material.dart';

import '../../core/utils/bidi_utils.dart';
import '../../l10n/app_localizations.dart';

class ChecklistRowData {
  static int _nextLocalId = 0;

  final String? id;
  final String text;
  final bool isCompleted;
  final String localId;

  ChecklistRowData({
    required this.id,
    required this.text,
    required this.isCompleted,
    String? localId,
  }) : localId = localId ?? 'draft_${_nextLocalId++}';

  ChecklistRowData copyWith({
    String? id,
    String? text,
    bool? isCompleted,
    String? localId,
  }) =>
      ChecklistRowData(
        id: id ?? this.id,
        text: text ?? this.text,
        isCompleted: isCompleted ?? this.isCompleted,
        localId: localId ?? this.localId,
      );
}

class ChecklistNoteView extends StatefulWidget {
  final List<ChecklistRowData> rows;
  final bool isEditing;
  final ValueChanged<List<ChecklistRowData>> onRowsChanged;
  final Future<void> Function(String id, bool isCompleted)? onToggle;
  final Future<void> Function(List<String> orderedIds)? onReorder;
  final Future<void> Function()? onRemoveCompleted;
  final VoidCallback? onEditFieldFocusRequested;
  final TextStyle? textStyle;

  const ChecklistNoteView({
    super.key,
    required this.rows,
    required this.isEditing,
    required this.onRowsChanged,
    this.onToggle,
    this.onReorder,
    this.onRemoveCompleted,
    this.onEditFieldFocusRequested,
    this.textStyle,
  });

  @override
  State<ChecklistNoteView> createState() => _ChecklistNoteViewState();
}

class _ChecklistNoteViewState extends State<ChecklistNoteView> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  ChecklistRowData? _ephemeralDraftRow;
  String? _pendingFocusKey;

  @override
  void didUpdateWidget(covariant ChecklistNoteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rows.isNotEmpty) {
      _ephemeralDraftRow = null;
    }
    _syncControllers();
  }

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _syncControllers() {
    final keys = widget.rows.map(_keyFor).toSet();
    for (final key in _controllers.keys.toList()) {
      if (!keys.contains(key)) {
        _controllers.remove(key)?.dispose();
        _focusNodes.remove(key)?.dispose();
      }
    }
    for (final row in widget.rows) {
      final key = _keyFor(row);
      final controller = _controllers.putIfAbsent(
        key,
        () => TextEditingController(text: row.text),
      );
      _focusNodes.putIfAbsent(key, FocusNode.new);
      if (controller.text != row.text && !_focusNodes[key]!.hasFocus) {
        controller.text = row.text;
      }
    }
  }

  String _keyFor(ChecklistRowData row) => row.localId;

  List<ChecklistRowData> get _visibleRows {
    final notDone = widget.rows.where((row) => !row.isCompleted).toList();
    final done = widget.rows.where((row) => row.isCompleted).toList();
    return [...notDone, ...done];
  }

  TextDirection _directionForRows(BuildContext context) {
    final text = widget.rows.map((row) => row.text).join('\n');
    return firstStrongOf(text) ?? Directionality.of(context);
  }

  void _replaceRow(ChecklistRowData row, String text) {
    var replaced = false;
    final next = widget.rows.map((r) {
      if (_keyFor(r) == _keyFor(row)) {
        replaced = true;
        return r.copyWith(text: text);
      }
      return r;
    }).toList();
    if (!replaced) next.add(row.copyWith(text: text));
    widget.onRowsChanged(next);
  }

  void _appendDraftAfter(ChecklistRowData row, String submittedText) {
    if (submittedText.trim().isEmpty) return;
    final next = widget.rows.map((r) {
      return _keyFor(r) == _keyFor(row) ? r.copyWith(text: submittedText) : r;
    }).toList();
    final index = next.indexWhere((r) => _keyFor(r) == _keyFor(row));
    final newRow = ChecklistRowData(id: null, text: '', isCompleted: false);
    next.insert(index < 0 ? next.length : index + 1, newRow);
    _pendingFocusKey = _keyFor(newRow);
    widget.onRowsChanged(next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _pendingFocusKey;
      if (!mounted || key == null) return;
      final focusNode = _focusNodes[key];
      if (focusNode != null) {
        focusNode.requestFocus();
      }
      _pendingFocusKey = null;
    });
  }

  void _toggleRow(ChecklistRowData row, bool isCompleted) {
    final rowKey = _keyFor(row);
    final remaining = widget.rows.where((r) => _keyFor(r) != rowKey).toList();
    final toggled = row.copyWith(isCompleted: isCompleted);
    final firstCompletedIndex =
        remaining.indexWhere((candidate) => candidate.isCompleted);
    final insertIndex = isCompleted
        ? (firstCompletedIndex == -1 ? remaining.length : firstCompletedIndex)
        : (firstCompletedIndex == -1 ? remaining.length : firstCompletedIndex);
    remaining.insert(insertIndex, toggled);
    widget.onRowsChanged(remaining);
    if (row.id != null) {
      widget.onToggle?.call(row.id!, isCompleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final rows = widget.isEditing && widget.rows.isEmpty
        ? [
            _ephemeralDraftRow ??=
                ChecklistRowData(id: null, text: '', isCompleted: false)
          ]
        : _visibleRows;
    final hasCompleted = widget.rows.any((row) => row.isCompleted);
    final direction = _directionForRows(context);

    return Directionality(
      textDirection: direction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasCompleted && widget.onRemoveCompleted != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                label: Text(AppStrings.of(context).removeDoneTasksLabel),
                onPressed: widget.onRemoveCompleted,
              ),
            ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: rows.length,
            onReorder: widget.isEditing
                ? (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex--;
                    final reordered = rows.toList();
                    final moved = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, moved);
                    widget.onRowsChanged(reordered);
                    final ids = reordered
                        .map((row) => row.id)
                        .whereType<String>()
                        .toList();
                    if (ids.isNotEmpty) await widget.onReorder?.call(ids);
                  }
                : (_, __) {},
            itemBuilder: (context, index) {
              final row = rows[index];
              final key = ValueKey(_keyFor(row));
              final controller = _controllers.putIfAbsent(
                _keyFor(row),
                () => TextEditingController(text: row.text),
              );
              final focusNode =
                  _focusNodes.putIfAbsent(_keyFor(row), FocusNode.new);
              final checkbox = Checkbox(
                value: row.isCompleted,
                onChanged: (value) => _toggleRow(row, value ?? false),
              );

              final text = widget.isEditing
                  ? Expanded(
                      child: Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: (_) {
                          widget.onEditFieldFocusRequested?.call();
                          focusNode.requestFocus();
                        },
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: widget.rows.isEmpty && index == 0,
                          maxLines: 1,
                          textInputAction: TextInputAction.done,
                          textDirection: direction,
                          style: (widget.textStyle ?? tt.bodyLarge)?.copyWith(
                            decoration: row.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: row.isCompleted ? cs.outline : null,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onTap: () {
                            widget.onEditFieldFocusRequested?.call();
                            focusNode.requestFocus();
                          },
                          onChanged: (value) => _replaceRow(row, value),
                          onEditingComplete: () {},
                          onSubmitted: (value) => _appendDraftAfter(row, value),
                        ),
                      ),
                    )
                  : Expanded(
                      child: Text(
                        row.text,
                        style: (widget.textStyle ?? tt.bodyLarge)?.copyWith(
                          decoration: row.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: row.isCompleted ? cs.outline : null,
                        ),
                      ),
                    );

              final dragHandle = widget.isEditing
                  ? ReorderableDelayedDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    )
                  : null;

              return Padding(
                key: key,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    checkbox,
                    const SizedBox(width: 8),
                    text,
                    if (dragHandle != null) ...[
                      const SizedBox(width: 8),
                      dragHandle,
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
