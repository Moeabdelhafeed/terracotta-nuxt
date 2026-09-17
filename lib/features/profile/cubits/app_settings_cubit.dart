import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/content_apis.dart';
import '../../../data/models/terracotta/content/app_settings.dart';
import '../../_shared/locale_scoped_load.dart';

typedef AppSettingsFetch =
    AsyncResult<AppSettings> Function({
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// «تواصل معنا» — how to reach the studio, and where to follow it.
///
/// `GET /api/app-settings`. It had been written and never called: the
/// social links, the WhatsApp number, the store links and the
/// business details all sat on the server unread, so the app offered
/// no way to contact the studio at all except by filing a formal
/// complaint.
///
/// **[LocaleScopedLoad].** Every row's `text` is written by the
/// server — «تواصل عبر واتساب» against «WhatsApp» — so a language
/// change has to ask again.
///
/// Public: no session, so a visitor can reach the studio too.
@immutable
class AppSettingsState {
  const AppSettingsState({this.settings, this.loading = true, this.error});

  final AppSettings? settings;
  final bool loading;
  final AppException? error;

  AppSettingsState copyWith({
    AppSettings? settings,
    bool? loading,
    AppException? error,
    bool clearError = false,
  }) => AppSettingsState(
    settings: settings ?? this.settings,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
  );
}

class AppSettingsCubit extends Cubit<AppSettingsState> with LocaleScopedLoad {
  AppSettingsCubit({AppSettingsFetch? fetch})
    : _fetch = fetch ?? ContentApis.getAppSettings,
      super(const AppSettingsState());

  final AppSettingsFetch _fetch;
  final _cancel = CancelToken();

  @override
  bool get hasData => state.settings != null;

  @override
  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));

    switch (await _fetch(cancelToken: _cancel)) {
      case Success(:final value):
        if (isClosed) return;
        emit(AppSettingsState(settings: value, loading: false));
      case Failure(:final error):
        if (isClosed) return;
        // What is on screen STAYS — a failed reload is not a reason to
        // take the studio's phone number away.
        emit(state.copyWith(loading: false, error: error));
    }
  }

  Future<void> refresh(String locale) => refreshIn(locale);

  @override
  Future<void> close() {
    _cancel.cancel('app settings closed');
    return super.close();
  }
}
