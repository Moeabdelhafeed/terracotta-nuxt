import 'animation_models.dart';

/// Public handle for driving a `GlobalAnimation` from outside its own
/// chrome.
///
/// Control used to mean holding a `GlobalKey<GlobalAnimationState>` and
/// calling methods on a `State` — which works, and also hands the
/// caller every private field in the class. This is the surface that is
/// actually meant to be used, mirroring `PdfHandle`.
abstract class AnimationHandle {
  AnimationStateSnapshot get state;
  Stream<AnimationStateSnapshot> get stateStream;

  // ─── Transport ────────────────────────────────────────────

  void play();
  void pause();
  void togglePlay();

  /// Back to the first frame, stopped.
  void reset();

  /// Reset and play in one call — what the replay button does.
  void replay();

  // ─── Position ─────────────────────────────────────────────

  /// Jump to a fraction of the composition, 0..1. A no-op for a GIF:
  /// Flutter's decoder owns the frame clock.
  void seekTo(double value);

  // ─── Rate ─────────────────────────────────────────────────

  /// Clamped to `[AnimationDefaults.minSpeed, maxSpeed]` — speed is a
  /// divisor of the composition's duration, so zero and negatives throw
  /// out of the controller. Ignored for a GIF, whose frame delays are
  /// in the file.
  void setSpeed(double speed);
}
