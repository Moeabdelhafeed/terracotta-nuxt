/// App-level permission status that wraps platform permission states
/// into a simplified model for UI decisions.
enum AppPermissionStatus {
  /// Permission has been granted.
  granted,

  /// Permission has been denied (can ask again).
  denied,

  /// Permission has been permanently denied (must go to settings).
  permanentlyDenied,

  /// Permission is restricted by the system (e.g. parental controls on iOS).
  restricted,

  /// Permission status is unknown or hasn't been requested yet.
  unknown,
  ;

  /// Whether the permission is currently usable.
  bool get isGranted => this == granted;

  /// Whether the user can be prompted to grant the permission.
  bool get canRequest => this == denied || this == unknown;

  /// Whether the user must go to app settings to grant the permission.
  bool get requiresSettings => this == permanentlyDenied || this == restricted;

  String get label => switch (this) {
    .granted => 'Granted',
    .denied => 'Denied',
    .permanentlyDenied => 'Permanently Denied',
    .restricted => 'Restricted',
    .unknown => 'Unknown',
  };
}
