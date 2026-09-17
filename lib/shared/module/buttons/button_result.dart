/// UI-state enum: the completion visual to display after a loading
/// operation finishes.
///
/// **Not** a `Result<T>` — see `lib/core/types/result.dart` for the
/// canonical value-or-error type. `ButtonResult` is a tri-state toggle
/// (`none` / `success` / `error`) consumed exclusively by buttons to
/// briefly render a checkmark or X before returning to idle. Map your
/// `Result<T>` outcome onto it at the call site:
///
/// ```dart
/// final r = await submit();
/// setState(() => _result = r is Success
///     ? ButtonResult.success
///     : ButtonResult.error);
/// ```
///
/// Example:
/// ```dart
/// GlobalFilledButton(
///   text: 'Submit',
///   onPressed: () => _submit(),
///   isLoading: _isLoading,
///   result: _result,
///   onResultShown: () => setState(() => _result = ButtonResult.none),
/// )
/// ```
enum ButtonResult {
  /// No completion result — button shows its normal state.
  none,

  /// Success — briefly shows a checkmark with a success color.
  success,

  /// Error — briefly shows an X with an error color.
  error,
}
