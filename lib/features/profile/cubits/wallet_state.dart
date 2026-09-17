import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';

/// «رصيد تيراكوتا» — what the customer has to spend.
@immutable
class WalletState {
  const WalletState({this.balance, this.loading = false, this.error});

  /// A DECIMAL STRING (`"150.00"`), exactly as the server sent it.
  /// Null before the first answer.
  final String? balance;

  final bool loading;
  final AppException? error;

  WalletState copyWith({
    String? balance,
    bool? loading,
    AppException? error,
    bool clearError = false,
  }) => WalletState(
    balance: balance ?? this.balance,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
  );
}
