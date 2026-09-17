part of '../global_text_field.dart';

// ---------------------------------------------------------------------------
// Feature extensions on _GlobalTextFormFieldState
//
// Each extension owns one orthogonal feature. Mixin-style split kept in
// part files so the State class stays the single owner of instance fields.
// ---------------------------------------------------------------------------

// ─── Undo / Redo ──────────────────────────────────────────────────────────

extension _UndoRedoExt on _GlobalTextFormFieldState {
  void _handleUndo() {
    final previous = _undoRedo.undo(widget.controller.text);
    if (previous == null) return;
    _isUndoRedoAction = true;
    widget.controller.text = previous;
    widget.controller.selection = TextSelection.collapsed(
      offset: previous.length,
    );
    _isUndoRedoAction = false;
    setState(() {});
  }

  void _handleRedo() {
    final next = _undoRedo.redo(widget.controller.text);
    if (next == null) return;
    _isUndoRedoAction = true;
    widget.controller.text = next;
    widget.controller.selection = TextSelection.collapsed(offset: next.length);
    _isUndoRedoAction = false;
    setState(() {});
  }
}

// ─── Chips ─────────────────────────────────────────────────────────────────

extension _ChipsExt on _GlobalTextFormFieldState {
  void _removeChip(String chip) {
    setState(() => _chips.remove(chip));
    widget.features.chips?.onChanged?.call(List.unmodifiable(_chips));
    if (mounted) {
      announceForAccessibility(
        context,
        Tr.t('text_field.chip_removed', 'Removed $chip'),
      );
    }
  }

  void _removeLastChip() {
    if (_chips.isEmpty) return;
    setState(() => _chips.removeLast());
    widget.features.chips?.onChanged?.call(List.unmodifiable(_chips));
  }

  /// Central add path for every source (submit / separator / suggestion
  /// pick): [ChipsConfig.beforeAdd] normalization first, then duplicate +
  /// max checks on the cleaned value. True when a chip actually landed.
  /// A duplicate pulses the existing chip instead of failing silently.
  bool _tryAddChip(String raw) {
    final cfg = widget.features.chips;
    if (cfg == null) return false;
    var tag = raw.trim();
    if (cfg.beforeAdd != null) {
      final cleaned = cfg.beforeAdd!(tag);
      if (cleaned == null) return false;
      tag = cleaned.trim();
    }
    if (tag.isEmpty) return false;
    if (cfg.max != null && _chips.length >= cfg.max!) return false;
    if (_chips.contains(tag)) {
      setState(() {
        _dupPulseChip = tag;
        _dupPulseTick++;
      });
      return false;
    }
    setState(() => _chips.add(tag));
    cfg.onChanged?.call(List.unmodifiable(_chips));
    if (mounted) {
      announceForAccessibility(
        context,
        Tr.t('text_field.chip_added', 'Added $tag'),
      );
    }
    return true;
  }

  /// [ChipsConfig.editOnTap] — the chip pops back into the editor as
  /// text (focused, caret at end) for correction.
  void _editChip(String chip) {
    _removeChip(chip);
    widget.controller.value = TextEditingValue(
      text: chip,
      selection: TextSelection.collapsed(offset: chip.length),
    );
    _effectiveFocusNode?.requestFocus();
    _updateSuggestions(chip);
  }

  /// Split [value] on [ChipsConfig.separators], chip every COMPLETE
  /// segment, return the remainder (after the last separator) for the
  /// editor. Unchanged value when no separator present.
  String _consumeSeparators(String value) {
    final cfg = widget.features.chips;
    if (cfg == null || cfg.separators.isEmpty) return value;
    if (!cfg.separators.any(value.contains)) return value;
    final pattern = RegExp(cfg.separators.map(RegExp.escape).join('|'));
    final parts = value.split(pattern);
    for (final part in parts.sublist(0, parts.length - 1)) {
      _tryAddChip(part);
    }
    return parts.last;
  }
}

// ─── Voice input ──────────────────────────────────────────────────────────

extension _VoiceExt on _GlobalTextFormFieldState {
  Future<void> _handleVoiceInput() async {
    final voice = widget.features.voice;
    if (voice == null) return;
    final adapter = voice.adapter;

    if (_isListening) {
      await adapter.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isListening = true);

    await adapter.start(
      localeId: voice.locale,
      onResult: (text, isFinal) {
        if (!mounted) return;
        widget.controller.text = text;
        widget.controller.selection = TextSelection.collapsed(
          offset: text.length,
        );
        widget.callbacks.onChanged?.call(text);
        if (isFinal) setState(() => _isListening = false);
      },
      onError: (error) {
        adapter.cancel();
        if (mounted) setState(() => _isListening = false);
      },
    );
  }
}

// ─── Password generate ────────────────────────────────────────────────────

extension _PasswordGenerateExt on _GlobalTextFormFieldState {
  /// Fill the field with a generated password
  /// ([TextFieldFeatures.passwordGenerator] or [PasswordGenerator.generate]),
  /// reveal it so the user can read/copy it — UNLESS the screen is being
  /// captured (`behavior.instantObscure`), where it stays hidden — and run
  /// the change + validation pipeline.
  void _handleGeneratePassword() {
    final generator =
        widget.features.passwordGenerator ?? PasswordGenerator.generate;
    final password = generator();
    widget.controller.text = password;
    widget.controller.selection = TextSelection.collapsed(
      offset: password.length,
    );
    // Reveal through the timeout-aware path — hidden under screen capture.
    if (!widget.behavior.instantObscure) _setObscured(false);
    widget.callbacks.onChanged?.call(password);
    widget.features.onPasswordGenerated?.call(password);
    _validation.markInteracted();
    _validation.handleTrigger(password);
    _notifyStrength(password);
    setState(() {});
  }
}

// ─── Inline completion accept ─────────────────────────────────────────────

extension _InlineCompletionExt on _GlobalTextFormFieldState {
  void _acceptInlineCompletion() {
    if (_completionText.isEmpty) return;
    final newText = '${widget.controller.text}$_completionText';
    _completionText = '';
    _ghostController?.ghost = '';
    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: newText.length,
    );
    widget.features.suggestions?.onSelected?.call(newText);
    setState(() {});
  }
}
