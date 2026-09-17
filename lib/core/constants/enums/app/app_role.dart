enum AppRole {
  guest,
  user,
  ;

  String get key => switch (this) {
    AppRole.guest => 'guest',
    AppRole.user => 'user',
  };

  String get label => switch (this) {
    AppRole.guest => 'Guest',
    AppRole.user => 'User',
  };
}
