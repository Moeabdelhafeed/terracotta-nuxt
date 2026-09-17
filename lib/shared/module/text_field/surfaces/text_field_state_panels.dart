part of '../global_text_field.dart';

// ---------------------------------------------------------------------------
// Panel + slot UI builders.
// Live in their own file so the main state class stays focused on
// lifecycle + control flow.
// ---------------------------------------------------------------------------

extension _PanelsExt on _GlobalTextFormFieldState {
  // ─── Header (identifier + info icon) ────────────────────────

  /// Identifier text with a trailing red `*` when the field is required —
  /// the star inherits the surrounding weight/size, only the color is
  /// pinned to the error role.
  Widget _identifierText(BuildContext context) {
    final label = widget.identifier!;
    if (!widget.required) return Text(label);
    return Text.rich(
      TextSpan(
        text: label,
        children: [
          TextSpan(
            text: ' *',
            style: TextStyle(color: context.statusColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (widget.identifier == null && widget.slots.infoLabel == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.identifier != null)
            Expanded(
              child: widget.features.animations.animateIdentifier
                  ? AnimatedDefaultTextStyle(
                      duration: AppDurations.quick,
                      style:
                          theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: _isFocused
                                ? TextFieldDefaults.identifierFocusedWeight
                                : TextFieldDefaults.identifierWeight,
                            fontSize: TextFieldDefaults.identifierFontSize,
                            color: _isFocused
                                ? context.primaryColors.primary
                                : theme.textTheme.bodyMedium?.color,
                          ) ??
                          TextStyle(
                            fontWeight: _isFocused
                                ? TextFieldDefaults.identifierFocusedWeight
                                : TextFieldDefaults.identifierWeight,
                            fontSize: TextFieldDefaults.identifierFontSize,
                            color: _isFocused
                                ? context.primaryColors.primary
                                : theme.textTheme.bodyMedium?.color,
                          ),
                      child: _identifierText(context),
                    )
                  : DefaultTextStyle.merge(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: TextFieldDefaults.identifierWeight,
                        fontSize: TextFieldDefaults.identifierFontSize,
                      ),
                      child: _identifierText(context),
                    ),
            ),
          if (widget.slots.infoLabel != null)
            Semantics(
              label: widget.slots.infoLabel,
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(context.radii.full),
                onTap: widget.slots.onInfoLabelTap,
                child: Padding(
                  padding: EdgeInsets.all(context.spacing.xs),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color:
                        widget.style.iconColor ??
                        (widget.behavior.enabled
                            ? theme.textTheme.bodyMedium?.color?.withValues(
                                alpha: 0.7,
                              )
                            : theme.colorScheme.outline),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Chips ──────────────────────────────────────────────────

  Widget _buildChips(BuildContext context) {
    final cfg = widget.features.chips;
    if (cfg == null || _chips.isEmpty) {
      return const SizedBox.shrink();
    }
    // Chips sit OUTSIDE the TextField's TapRegion but are part of this
    // composite — flag their pointers (same guard as the overlay) so a
    // chip tap (edit / delete) doesn't run the tap-outside unfocus
    // watcher and blur the editor.
    return Listener(
      onPointerDown: (_) => _isInteractingWithOverlay = true,
      onPointerUp: (_) => _isInteractingWithOverlay = false,
      onPointerCancel: (_) => _isInteractingWithOverlay = false,
      child: Padding(
        padding: EdgeInsets.only(bottom: context.spacing.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 100),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var i = 0; i < _chips.length; i++)
                  _buildOneChip(context, cfg, _chips[i], i),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOneChip(
    BuildContext context,
    ChipsConfig cfg,
    String chip,
    int index,
  ) {
    // Display-only surface: readOnly / disabled fields keep the chips but
    // drop the delete + edit affordances.
    final interactive = widget.behavior.enabled && !widget.behavior.readOnly;

    Widget built;
    if (cfg.chipBuilder != null) {
      built = cfg.chipBuilder!(context, chip, () => _removeChip(chip));
    } else {
      final style = cfg.style;
      // An ACTION chip, not a choice one: tapping a tag opens it for
      // editing, and it has no selected state to announce.
      built = GlobalChip(
        label: chip,
        variant: ChipVariant.filled,
        onDeleted: interactive ? () => _removeChip(chip) : null,
        onPressed: interactive && cfg.editOnTap ? () => _editChip(chip) : null,
        // The caller's bag IS the chip's bag now, so only the two
        // defaults this surface owns are filled in: a tag is a solid
        // primary pill, not the chip module's resting grey.
        style: ChipStyle(
          backgroundColor: context.primaryColors.primary,
          labelColor: context.textColors.onPrimary,
          borderRadius: BorderRadius.circular(context.radii.full),
        ).mergedWith(style),
      );
    }

    built = Semantics(
      label: Tr.t(
        'text_field.chip_semantics',
        'Tag ${index + 1} of ${_chips.length}: $chip',
      ),
      child: built,
    );

    // Duplicate-add feedback: one-shot scale pulse on the chip the
    // rejected value already matches. Keyed by tick so a repeat dup on
    // the same chip replays.
    if (chip == _dupPulseChip) {
      built = TweenAnimationBuilder<double>(
        key: ValueKey('chip-pulse-$_dupPulseTick'),
        tween: Tween(begin: 0, end: 1),
        duration: AppDurations.normal,
        curve: Curves.easeOut,
        child: built,
        builder: (context, t, child) => Transform.scale(
          scale: 1 + sin(t * 3.14159) * 0.12,
          child: child,
        ),
      );
    }
    return built;
  }

  // ─── Count row (char + word) ────────────────────────────────

  Widget _buildCountRow(BuildContext context) {
    final counters = widget.features.counters;
    final showCharCount =
        counters.showCharCount && widget.behavior.maxLength != null;
    final showWordCount = counters.showWordCount;
    final chipsCfg = widget.features.chips;
    final showTagCount =
        (chipsCfg?.showCounter ?? false) && chipsCfg?.max != null;

    if (!showCharCount && !showWordCount && !showTagCount) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final text = widget.controller.text;
    final currentLength = text.length;
    final wordCount = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    var counterColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    if (showCharCount) {
      final maxLen = widget.behavior.maxLength!;
      final ratio = currentLength / maxLen;
      if (ratio >= 1.0) {
        counterColor = _rs.errorBorder.color;
      } else if (ratio >= 0.8) {
        counterColor = _rs.counterWarningColor;
      }
    }

    final parts = <String>[];
    if (showTagCount) {
      // Tag counter runs hot at the cap (adds are silently ignored there
      // — the warning color is the tell).
      if (_chips.length >= chipsCfg!.max!) {
        counterColor = _rs.counterWarningColor;
      }
      parts.add('${_chips.length}/${chipsCfg.max}');
    }
    if (showWordCount) {
      parts.add(
        '$wordCount ${wordCount == 1 ? TextFieldStrings.word : TextFieldStrings.words}',
      );
    }
    if (showCharCount) {
      parts.add(
        '$currentLength/${widget.behavior.maxLength}${showWordCount ? ' ${TextFieldStrings.chars}' : ''}',
      );
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: context.spacing.xs,
        end: context.spacing.xs,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Text(
          parts.join(' · '),
          style:
              _rs.charCountStyle ??
              theme.textTheme.bodySmall?.copyWith(
                color: counterColor,
                fontSize: 12,
              ),
        ),
      ),
    );
  }

  // Success state is rendered by `_buildFieldMessages` (as a success message)
  // so `features.showSuccess` / `successText` share the multi-state styling.

  // ─── Field messages (multi-state notes) ─────────────────────

  /// Column below the field: the validator error (rendered in the error
  /// message state — same icon + status color as the rest) followed by any
  /// caller [FieldMessage]s, grouped by severity (error → success → warning →
  /// info), insertion order preserved within a group. This column is the ONLY
  /// place validator errors render — Form fields included (`formValidator`
  /// stores its result here; Material's duplicate string is collapsed).
  Widget _buildFieldMessages(BuildContext context) {
    final v = widget.validation;
    final hideError =
        v.requirements != null &&
        v.requirements!.isNotEmpty &&
        v.hideErrorWhenRequirements;
    final validationError = hideError
        ? null
        : (v.errorText ?? _validation.effectiveError);
    final messages = widget.messages;

    // Feature-driven success (`features.showSuccess` / `successText`) renders as
    // a success message here — same state as the rest — when the field is valid
    // and not mid-async-check. Caller error-messages also veto it.
    final f = widget.features;
    final hasErr =
        _validation.effectiveError != null ||
        _validation.isValidatingAsync ||
        v.errorText != null ||
        messages.any((m) => m.type == FieldMessageType.error);
    final showSuccess = !hasErr && (f.showSuccess || f.successText != null);

    // Hardware-keyboard Caps Lock warning while focused.
    final capsWarning =
        f.warnCapsLock &&
        _capsLockOn &&
        (_effectiveFocusNode?.hasFocus ?? false);

    if (validationError == null &&
        !showSuccess &&
        !capsWarning &&
        messages.isEmpty) {
      return const SizedBox.shrink();
    }

    final status = context.statusColors;
    Color colorFor(FieldMessageType t) => switch (t) {
      FieldMessageType.error => status.error,
      FieldMessageType.success => status.success,
      FieldMessageType.warning => status.warning,
      FieldMessageType.info => status.info,
    };

    final anim = f.animations.messageAnimation;
    final slideFrom = f.animations.messageSlideFrom;

    // Keyed on content so an entrance replays when a row's text changes,
    // but NOT on every rebuild while the row is stable.
    Widget row(String keyPrefix, IconData icon, String text, Color color) =>
        _AnimatedMessageRow(
          key: ValueKey('$keyPrefix:$text'),
          animation: anim,
          slideFrom: slideFrom,
          icon: icon,
          text: text,
          color: color,
        );

    // Build the rows grouped by severity: error(s) → success → warning → info,
    // insertion order preserved within each group.
    final rows = <Widget>[
      // ── error ──
      if (validationError != null)
        v.errorBuilder != null
            ? _AnimatedMessageRow(
                key: ValueKey('error-custom:$validationError'),
                animation: anim,
                slideFrom: slideFrom,
                text: validationError,
                color: status.error,
                custom: v.errorBuilder!(context, validationError),
              )
            : row(
                'error',
                v.errorIcon ?? FieldMessageType.error.defaultIcon,
                validationError,
                status.error,
              ),
      for (final m in messages.where((m) => m.type == FieldMessageType.error))
        row('m-error', m.icon ?? m.type.defaultIcon, m.text, status.error),
      // ── success ──
      if (showSuccess)
        row(
          'success',
          FieldMessageType.success.defaultIcon,
          f.successText ?? '',
          status.success,
        ),
      for (final m in messages.where((m) => m.type == FieldMessageType.success))
        row('m-success', m.icon ?? m.type.defaultIcon, m.text, status.success),
      // ── warning + info ──
      if (capsWarning)
        row(
          'caps',
          Icons.keyboard_capslock,
          TextFieldStrings.capsLockOn,
          status.warning,
        ),
      for (final type in const [
        FieldMessageType.warning,
        FieldMessageType.info,
      ])
        for (final m in messages.where((m) => m.type == type))
          row(
            'm-${type.name}',
            m.icon ?? m.type.defaultIcon,
            m.text,
            colorFor(type),
          ),
    ];

    // Live region so screen readers announce rows as they appear (errors,
    // async results, success) without moving focus.
    //
    // AnimatedSize anchors to the top-START and does NOT clip: a center
    // anchor clipped both edges while the width animated (rows looked like
    // they slid in from the right, sheared), and slide entrances need to
    // overshoot the box briefly.
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          top: context.spacing.xs,
          start: context.spacing.xs,
        ),
        child: AnimatedSize(
          duration: AppDurations.quick,
          curve: Curves.easeOut,
          alignment: AlignmentDirectional.topStart,
          clipBehavior: Clip.none,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in rows)
                Padding(
                  padding: EdgeInsets.only(bottom: context.spacing.xs),
                  child: r,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Strength bar ───────────────────────────────────────────

  Widget _buildStrengthBar(BuildContext context) {
    final v = widget.validation;
    final hasReqs = v.requirements != null && v.requirements!.isNotEmpty;
    if (!v.showStrengthBar || (!hasReqs && v.strengthEstimator == null)) {
      return const SizedBox.shrink();
    }

    final value = widget.controller.text;
    // Estimator (real entropy-style score) wins over the requirements
    // ratio; with an estimator and no checklist, a fixed segment count.
    final progress = value.isEmpty ? 0.0 : (v.strengthOf(value) ?? 0.0);
    final segments = hasReqs
        ? v.requirements!.length
        : TextFieldDefaults.strengthSegmentsDefault;
    final filledCount = (progress * segments).round().clamp(0, segments);

    Color barColor;
    if (progress <= 0.5) {
      barColor = Color.lerp(
        _rs.strengthWeakColor,
        _rs.strengthMediumColor,
        progress * 2,
      )!;
    } else {
      barColor = Color.lerp(
        _rs.strengthMediumColor,
        _rs.strengthStrongColor,
        (progress - 0.5) * 2,
      )!;
    }

    final theme = Theme.of(context);
    final emptyColor = theme.colorScheme.onSurface.withValues(alpha: 0.1);
    final weak = TextFieldStrings.strengthWeak;
    final medium = TextFieldStrings.strengthMedium;
    final strong = TextFieldStrings.strengthStrong;
    final label = progress >= 1.0
        ? strong
        : progress >= 0.5
        ? medium
        : weak;

    // Reserve the widest label's width so the bar doesn't resize as
    // Weak/Medium/Strong swap.
    final labelStyle = theme.textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w600,
    );
    final scaler = MediaQuery.textScalerOf(context);
    var labelWidth = 0.0;
    for (final l in [weak, medium, strong]) {
      final painter = TextPainter(
        text: TextSpan(text: l, style: labelStyle),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > labelWidth) labelWidth = painter.width;
    }

    // One rounded segment per requirement (filled left-to-right as they
    // pass) + an animated strength label at the end.
    return Padding(
      padding: EdgeInsetsDirectional.only(top: context.spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < segments; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: i == segments - 1 ? 0 : context.spacing.xs,
                      ),
                      child: AnimatedContainer(
                        duration: AppDurations.normal,
                        curve: Curves.easeOut,
                        height: TextFieldDefaults.strengthSegmentHeight,
                        decoration: BoxDecoration(
                          color: i < filledCount ? barColor : emptyColor,
                          borderRadius: BorderRadius.circular(
                            TextFieldDefaults.strengthSegmentHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // No reserved space while empty — the bar spans the full row until
          // typing starts, then the label slot animates in at a FIXED width
          // (widest of Weak/Medium/Strong) so swaps don't resize the bar.
          AnimatedSize(
            duration: AppDurations.quick,
            curve: Curves.easeOut,
            child: value.isEmpty
                ? const SizedBox.shrink()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: context.spacing.sm),
                      SizedBox(
                        width: labelWidth.ceilToDouble(),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: AppDurations.normal,
                            style: labelStyle.copyWith(color: barColor),
                            child: Text(label, maxLines: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Requirements checklist ─────────────────────────────────

  Widget _buildRequirements(BuildContext context) {
    final v = widget.validation;
    if (v.requirements == null || v.requirements!.isEmpty) {
      return const SizedBox.shrink();
    }

    final value = widget.controller.text;
    final theme = Theme.of(context);

    final reqs = v.requirements!;
    final visibleReqs = v.hidePassedRequirements
        ? reqs.where((r) => value.isEmpty || !r.test(value)).toList()
        : reqs;

    if (visibleReqs.isEmpty) return const SizedBox.shrink();

    // singleLine: the sort-mode Stack uses fixed-height rows, so long
    // labels ellipsize; the plain column lets them wrap instead.
    Widget row(FieldRequirement req, bool passed, {required bool singleLine}) =>
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: singleLine
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            if (!v.requirementsTextOnly) ...[
              AnimatedSwitcher(
                duration: AppDurations.quick,
                child: Icon(
                  passed ? Icons.check_circle : Icons.circle_outlined,
                  key: ValueKey('${req.label}_$passed'),
                  size: 16,
                  color: passed
                      ? _rs.requirementPassedColor
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              SizedBox(width: context.spacing.sm),
            ],
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: AppDurations.quick,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: passed
                      ? _rs.requirementPassedColor
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  decoration: passed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
                child: Text(
                  req.label,
                  maxLines: singleLine ? 1 : null,
                  overflow: singleLine ? TextOverflow.ellipsis : null,
                ),
              ),
            ),
          ],
        );

    Widget body;
    if (v.sortPassedRequirements && !v.hidePassedRequirements) {
      // Animated reorder: passed rows slide to the bottom. Fixed-height rows
      // in a Stack; each row keeps a stable identity (its label) and
      // AnimatedPositioned tweens it to its sorted slot. Requires
      // single-line labels (documented on the flag).
      final fontSize = MediaQuery.textScalerOf(
        context,
      ).scale(theme.textTheme.bodySmall!.fontSize ?? 12);
      final lineHeight = fontSize * (theme.textTheme.bodySmall!.height ?? 1.4);
      final rowHeight =
          (lineHeight > 16 ? lineHeight : 16.0) + context.spacing.xs;

      final passedByIndex = [
        for (final req in reqs) value.isNotEmpty && req.test(value),
      ];
      // Sorted slot per original index: unmet first (original order), then
      // passed (original order).
      final order = <int>[
        for (var i = 0; i < reqs.length; i++)
          if (!passedByIndex[i]) i,
        for (var i = 0; i < reqs.length; i++)
          if (passedByIndex[i]) i,
      ];
      final slotOf = List<int>.filled(reqs.length, 0);
      for (var slot = 0; slot < order.length; slot++) {
        slotOf[order[slot]] = slot;
      }

      body = SizedBox(
        height: rowHeight * reqs.length,
        width: double.infinity,
        child: Stack(
          children: [
            for (var i = 0; i < reqs.length; i++)
              AnimatedPositionedDirectional(
                key: ValueKey(reqs[i].label),
                duration: AppDurations.normal,
                curve: Curves.easeOutCubic,
                top: slotOf[i] * rowHeight,
                start: 0,
                end: 0,
                height: rowHeight,
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: row(reqs[i], passedByIndex[i], singleLine: true),
                ),
              ),
          ],
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final req in visibleReqs)
            Padding(
              padding: EdgeInsets.only(bottom: context.spacing.xs),
              child: row(
                req,
                value.isNotEmpty && req.test(value),
                singleLine: false,
              ),
            ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: context.spacing.sm,
        start: context.spacing.xs,
      ),
      child: AnimatedSize(
        duration: AppDurations.quick,
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: body,
      ),
    );
  }

  // ─── Suggestion rows (shared by overlay + inline) ───────────

  /// Recent + suggestion + loading rows, used by both the anchored overlay
  /// (controller) and the inline panel. Callers differ only in the outer
  /// container and the clear-all action ([onClearTap]).
  List<Widget> _suggestionRows(
    BuildContext context, {
    required bool includeLoading,
    required VoidCallback onClearTap,
  }) {
    final cfg = widget.features.suggestions!;
    final theme = Theme.of(context);
    final query = widget.controller.text;
    final lowerQuery = query.toLowerCase().trim();
    final filteredRecent = _filterRecentSearches(lowerQuery);
    final showRecent = filteredRecent.isNotEmpty;
    final showSuggestions = _filteredSuggestions.isNotEmpty;

    Widget suggestionRow(String s, BorderRadius? radius) =>
        cfg.itemBuilder != null
        ? Semantics(
            button: true,
            label: s,
            child: InkWell(
              canRequestFocus: false, // overlay rows
              borderRadius: radius,
              onTap: () => _selectSuggestion(s),
              child: cfg.itemBuilder!(
                context,
                s,
                widget.controller.text.trim().toLowerCase() == s.toLowerCase(),
              ),
            ),
          )
        : _buildSuggestionItem(context, s, query, inkRadius: radius);

    // Rows as radius-aware builders — the FIRST and LAST rows round their
    // ink to the popup's top/bottom corners.
    final builders = <Widget Function(BorderRadius?)>[
      if (showRecent) ...[
        ...filteredRecent.map(
          (r) =>
              (radius) => _buildRecentSearchItem(context, r, inkRadius: radius),
        ),
        if (cfg.onRecentCleared != null)
          (radius) => InkWell(
            canRequestFocus: false, // overlay rows
            borderRadius: radius,
            onTap: onClearTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.md,
                vertical: context.spacing.sm,
              ),
              child: Text(
                TextFieldStrings.clearAll,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        if (showSuggestions) (_) => const GlobalDivider(),
      ],
      if (showSuggestions)
        ..._groupedSuggestionBuilders(context, suggestionRow),
      if (includeLoading && _isLoadingSuggestions)
        (_) => const _SuggestionsShimmerRow(),
    ];

    final popupRadius = _effectiveBorderRadius;
    BorderRadius? radiusFor(int i) {
      final isFirst = i == 0;
      final isLast = i == builders.length - 1;
      if (!isFirst && !isLast) return null;
      return BorderRadius.only(
        topLeft: isFirst ? popupRadius.topLeft : Radius.zero,
        topRight: isFirst ? popupRadius.topRight : Radius.zero,
        bottomLeft: isLast ? popupRadius.bottomLeft : Radius.zero,
        bottomRight: isLast ? popupRadius.bottomRight : Radius.zero,
      );
    }

    return [
      for (var i = 0; i < builders.length; i++) builders[i](radiusFor(i)),
    ];
  }

  /// Suggestion rows with SECTION HEADERS interleaved wherever
  /// [SuggestionsConfig.groupBy]'s label changes (order-preserving walk).
  List<Widget Function(BorderRadius?)> _groupedSuggestionBuilders(
    BuildContext context,
    Widget Function(String suggestion, BorderRadius? radius) rowBuilder,
  ) {
    final cfg = widget.features.suggestions!;
    final out = <Widget Function(BorderRadius?)>[];
    String? lastGroup;
    for (final s in _filteredSuggestions) {
      final group = cfg.groupBy?.call(s);
      if (group != null && group != lastGroup) {
        lastGroup = group;
        out.add((_) => _suggestionGroupHeader(context, group));
      }
      out.add((radius) => rowBuilder(s, radius));
    }
    return out;
  }

  /// Non-interactive section header — mirrors the dropdown's group header
  /// (accent bar + small uppercase label).
  Widget _suggestionGroupHeader(BuildContext context, String label) {
    final primary = context.primaryColors.primary;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.spacing.md,
        end: context.spacing.md,
        top: context.spacing.sm,
        bottom: context.spacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: context.spacing.sm + context.spacing.xs,
            margin: EdgeInsetsDirectional.only(end: context.spacing.sm),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(context.radii.xs),
            ),
          ),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Inline suggestions panel ───────────────────────────────

  Widget _buildInlineSuggestions(BuildContext context) {
    final cfg = widget.features.suggestions;
    if (cfg == null || !cfg.inline) return const SizedBox.shrink();

    final focusNode = _effectiveFocusNode;
    if (focusNode == null || !focusNode.hasFocus) {
      return const SizedBox.shrink();
    }

    final query = widget.controller.text;
    final lowerQuery = query.toLowerCase().trim();

    final filteredRecent = _filterRecentSearches(lowerQuery);
    final showRecent = filteredRecent.isNotEmpty;
    final showSuggestions = _filteredSuggestions.isNotEmpty;

    if (!showRecent && !showSuggestions) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final borderRadius = _effectiveBorderRadius;

    return AnimatedSize(
      duration: AppDurations.quick,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: borderRadius,
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _suggestionRows(
                  context,
                  includeLoading: false,
                  onClearTap: () {
                    cfg.onRecentCleared?.call();
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Suffix slot composition ────────────────────────────────

  /// Composes the async-validation spinner (when in flight) in front of the
  /// regular suffix content.
  Widget? _buildSuffixIcon() {
    final base = _buildSuffixIconBase();
    if (!_validation.isValidatingAsync) return base;
    final spinner = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 16,
        height: 16,
        child: GlobalProgress.loading(
          type: ProgressType.circular,
          style: ProgressStyle(thickness: 2, color: _suffixIconColor),
        ),
      ),
    );
    if (base == null) return spinner;
    return Row(mainAxisSize: MainAxisSize.min, children: [spinner, base]);
  }

  Widget? _buildSuffixIconBase() {
    if (widget.features.suffixLoading) return _buildLoadingSuffix();

    final explicit = widget.slots.suffix;
    if (explicit != null) {
      return switch (explicit) {
        SuffixLoading() => _buildLoadingSuffix(),
        // A tappable icon gets the shared 32px-min IconButton; a null onTap
        // renders a plain decorative icon (an IconButton with a null handler
        // would paint as disabled).
        SuffixIcon(:final icon, :final onTap) =>
          onTap != null
              ? _suffixIconButton(icon: icon, onPressed: onTap)
              // End-only inset: content padding already separates the icon
              // from the text; the end inset keeps it off the field border.
              : Padding(
                  padding: EdgeInsetsDirectional.only(end: context.spacing.md),
                  child: Icon(icon, color: _suffixIconColor, size: 20),
                ),
        SuffixAsset(:final path) => Padding(
          padding: const EdgeInsets.all(8),
          child: GlobalImage.a(
            path,
            width: 24,
            height: 24,
            style: ImageStyle(
              color: _suffixIconColor,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        SuffixWidget(:final child) => child,
      };
    }

    if (widget.behavior.obscureText && widget.features.showObscureToggle) {
      if (!widget.features.showPasswordGenerate) return _buildObscureToggle();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _suffixIconButton(
            icon: Icons.auto_awesome,
            tooltip: TextFieldStrings.generatePassword,
            onPressed: _handleGeneratePassword,
          ),
          _buildObscureToggle(),
        ],
      );
    }

    final hasClear =
        widget.features.showClearButton && widget.controller.text.isNotEmpty;
    final hasVoice = widget.features.voice != null;
    final hasUndoRedo = widget.features.enableUndoRedo;
    final canUndo = hasUndoRedo && _undoRedo.canUndo;
    final canRedo = hasUndoRedo && _undoRedo.canRedo;

    if (!hasClear && !hasVoice && !canUndo && !canRedo) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canUndo)
          _suffixIconButton(
            icon: Icons.undo,
            tooltip: TextFieldStrings.undo,
            onPressed: _handleUndo,
          ),
        if (canRedo)
          _suffixIconButton(
            icon: Icons.redo,
            tooltip: TextFieldStrings.redo,
            onPressed: _handleRedo,
          ),
        if (hasClear)
          _suffixIconButton(
            icon: Icons.close,
            tooltip: TextFieldStrings.clear,
            onPressed: () {
              widget.controller.clear();
              widget.features.onClear?.call();
              widget.callbacks.onChanged?.call('');
              setState(() {});
            },
          ),
        if (hasVoice)
          _suffixIconButton(
            icon: _isListening ? Icons.mic : Icons.mic_outlined,
            tooltip: TextFieldStrings.voiceInput,
            color: _isListening ? Theme.of(context).colorScheme.error : null,
            onPressed: _handleVoiceInput,
          ),
      ],
    );
  }

  Widget _suffixIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? color,
  }) {
    return GlobalIconButton(
      iconData: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      enforceMinTouchTarget: false,
      iconSize: 20,
      style: ButtonStateStyle(
        foregroundColor: color ?? _suffixIconColor,
        width: 40,
        height: 40,
      ),
    );
  }

  Widget _buildLoadingSuffix() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 20,
        height: 20,
        child: GlobalProgress.loading(
          type: ProgressType.circular,
          style: const ProgressStyle(thickness: 2),
        ),
      ),
    );
  }

  Widget _buildObscureToggle() {
    if (widget.behavior.revealMode == TextFieldRevealMode.holdToReveal) {
      // Press-and-hold reveals, release re-hides. GestureDetector (not
      // IconButton) so press≠tap; visual box mirrors _suffixIconButton.
      final label = TextFieldStrings.holdToReveal;
      // Same IconButton as the toggle variant (identical spacing/ripple);
      // the hold gesture rides a raw Listener — pointer events bypass the
      // gesture arena, so the button's own tap handling doesn't interfere.
      return Listener(
        onPointerDown: (_) => _setObscured(false),
        onPointerUp: (_) => _setObscured(true),
        onPointerCancel: (_) => _setObscured(true),
        child: _suffixIconButton(
          icon: _obscureText ? Icons.visibility_off : Icons.visibility,
          tooltip: label,
          onPressed: () {}, // hold handled by the Listener above
        ),
      );
    }
    return _suffixIconButton(
      icon: _obscureText ? Icons.visibility_off : Icons.visibility,
      tooltip: TextFieldStrings.toggleVisibility,
      onPressed: _toggleObscureText,
    );
  }
}

// ---------------------------------------------------------------------------
// _AnimatedMessageRow — one message-column row with an entrance animation
// ---------------------------------------------------------------------------

/// A single row of the field's message column. Plays its
/// [FieldMessageAnimation] entrance once on mount (the parent keys rows on
/// content, so a changed text re-mounts and replays).
///
/// * `fade` / `slide` — opacity (+ directional offset) into place.
/// * `typed` — character-by-character reveal; duration scales with length
///   ([TextFieldDefaults.messageTypedMsPerChar], clamped). A [custom] child
///   (errorBuilder row) can't be typewritten and falls back to `fade`.
/// * Reduced motion (`MediaQuery.disableAnimations`) jumps straight to the
///   settled state.
class _AnimatedMessageRow extends StatefulWidget {
  const _AnimatedMessageRow({
    super.key,
    required this.animation,
    required this.slideFrom,
    required this.text,
    required this.color,
    this.icon,
    this.custom,
  });

  final FieldMessageAnimation animation;
  final FieldMessageSlideFrom slideFrom;
  final IconData? icon;
  final String text;
  final Color color;

  /// Caller-built row (validation `errorBuilder`) — rendered as-is.
  final Widget? custom;

  @override
  State<_AnimatedMessageRow> createState() => _AnimatedMessageRowState();
}

class _AnimatedMessageRowState extends State<_AnimatedMessageRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _started = false;

  FieldMessageAnimation get _effective =>
      (widget.custom != null && widget.animation == FieldMessageAnimation.typed)
      ? FieldMessageAnimation.fade
      : widget.animation;

  Duration get _duration {
    if (_effective == FieldMessageAnimation.typed) {
      final ms = (widget.text.length * TextFieldDefaults.messageTypedMsPerChar)
          .clamp(
            TextFieldDefaults.messageTypedMinMs,
            TextFieldDefaults.messageTypedMaxMs,
          );
      return Duration(milliseconds: ms);
    }
    return AppDurations.quick;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_effective == FieldMessageAnimation.none ||
        MediaQuery.disableAnimationsOf(context)) {
      _ctrl.value = 1;
    } else {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Offset _slideBegin(BuildContext context) {
    final ltr = Directionality.of(context) == TextDirection.ltr;
    const f = TextFieldDefaults.messageSlideFraction;
    return switch (widget.slideFrom) {
      FieldMessageSlideFrom.top => const Offset(0, -f),
      FieldMessageSlideFrom.bottom => const Offset(0, f),
      FieldMessageSlideFrom.start => Offset(ltr ? -f : f, 0),
      FieldMessageSlideFrom.end => Offset(ltr ? f : -f, 0),
    };
  }

  /// Icon boxed to one text line and centered there, row top-aligned — the
  /// icon sits on the FIRST line's centre whether the text wraps or not.
  Widget _standardRow(BuildContext context, String visibleText) {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: widget.color);
    final lineHeight = (style?.fontSize ?? 12) * (style?.height ?? 1.4);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: lineHeight,
          child: Center(
            child: Icon(
              widget.icon,
              size: TextFieldDefaults.messageIconSize,
              color: widget.color,
            ),
          ),
        ),
        if (widget.text.isNotEmpty) ...[
          SizedBox(width: context.spacing.xs),
          Flexible(child: Text(visibleText, style: style)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    switch (_effective) {
      case FieldMessageAnimation.none:
        return widget.custom ?? _standardRow(context, widget.text);
      case FieldMessageAnimation.typed:
        return AnimatedBuilder(
          animation: curved,
          builder: (context, _) {
            final n = (widget.text.length * curved.value).round().clamp(
              0,
              widget.text.length,
            );
            return _standardRow(context, widget.text.substring(0, n));
          },
        );
      case FieldMessageAnimation.fade:
        return FadeTransition(
          opacity: curved,
          child: widget.custom ?? _standardRow(context, widget.text),
        );
      case FieldMessageAnimation.slide:
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: _slideBegin(context),
              end: Offset.zero,
            ).animate(curved),
            child: widget.custom ?? _standardRow(context, widget.text),
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Suggestions loading skeleton
// ---------------------------------------------------------------------------

/// Loading state for the suggestions overlay — a "Searching…" header plus two
/// skeleton result rows pulsing with the shimmer palette (replaces the old
/// centered spinner, which read as a stall rather than incoming rows).
class _SuggestionsShimmerRow extends StatefulWidget {
  const _SuggestionsShimmerRow();

  @override
  State<_SuggestionsShimmerRow> createState() => _SuggestionsShimmerRowState();
}

class _SuggestionsShimmerRowState extends State<_SuggestionsShimmerRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.shimmer,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(BuildContext context, double width) {
    final shimmer = context.shimmerColors;
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: shimmer.baseColor,
        borderRadius: BorderRadius.circular(context.radii.xs),
      ),
    );
  }

  Widget _skeletonRow(BuildContext context, double barWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md,
        vertical: context.spacing.sm,
      ),
      child: Row(
        children: [
          // Text-secondary, not the shimmer highlight — the highlight tint
          // was near-invisible under the row's fade.
          Icon(
            Icons.search_rounded,
            size: 16,
            color: context.textColors.secondary,
          ),
          SizedBox(width: context.spacing.sm),
          _bar(context, barWidth),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final secondary = context.textColors.secondary;
    return FadeTransition(
      // Floor at 0.55 — a deeper fade left the icons nearly invisible.
      opacity: Tween<double>(begin: 0.55, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: context.spacing.md,
              right: context.spacing.md,
              top: context.spacing.sm,
            ),
            child: Text(
              // ARB-key TODO: add `text_field_searching` on the next
              // intl codegen pass.
              Tr.t('text_field.searching', 'Searching…'),
              style: context.textTheme.bodySmall?.copyWith(color: secondary),
            ),
          ),
          _skeletonRow(context, 160),
          _skeletonRow(context, 110),
        ],
      ),
    );
  }
}
