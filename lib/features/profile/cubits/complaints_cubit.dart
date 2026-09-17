import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/inbox_apis.dart';
import '../../../data/models/terracotta/account/complaint.dart';

typedef ComplaintsFetch =
    AsyncResult<List<Complaint>> Function({
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef ComplaintSend =
    AsyncResult<Complaint> Function({
      required String type,
      required String message,
      String? name,
      String? contact,
      String? reference,
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// «تواصل معنا» — what the customer told the studio, and telling it.
///
/// `GET /api/complaints` is the caller's OWN list and needs a session;
/// `POST /api/complaints` is public — a signed-out visitor can send
/// one, and then has to say who they are.
@immutable
class ComplaintsState {
  const ComplaintsState({
    this.items = const [],
    this.loading = true,
    this.sending = false,
    this.error,
    this.fieldErrors = const {},
  });

  final List<Complaint> items;
  final bool loading;
  final bool sending;
  final AppException? error;

  /// The server's words, keyed to the box they belong under — a 422
  /// here names `message`, `name`, `contact` or `type`. HTML in the
  /// message is one of them: the server REFUSES it rather than
  /// stripping it, so the customer has to be told.
  final Map<String, String> fieldErrors;

  ComplaintsState copyWith({
    List<Complaint>? items,
    bool? loading,
    bool? sending,
    AppException? error,
    bool clearError = false,
    Map<String, String>? fieldErrors,
  }) => ComplaintsState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    sending: sending ?? this.sending,
    error: clearError ? null : error ?? this.error,
    fieldErrors: fieldErrors ?? this.fieldErrors,
  );
}

class ComplaintsCubit extends Cubit<ComplaintsState> {
  ComplaintsCubit({ComplaintsFetch? fetch, ComplaintSend? send})
    : _fetch = fetch ?? InboxApis.getComplaints,
      _send = send ?? InboxApis.sendComplaint,
      super(const ComplaintsState());

  final ComplaintsFetch _fetch;
  final ComplaintSend _send;
  final _cancel = CancelToken();

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));

    switch (await _fetch(cancelToken: _cancel)) {
      case Success(:final value):
        if (isClosed) return;
        emit(state.copyWith(items: value, loading: false));
      case Failure(:final error):
        if (isClosed) return;
        // What is on screen STAYS. A failed refresh is not a reason to
        // blank a list the customer was reading.
        emit(state.copyWith(loading: false, error: error));
    }
  }

  /// File one. Answers whether it went.
  ///
  /// [name] and [contact] are the SIGNED-OUT fields: the server takes
  /// them from the account when there is a session and ignores what is
  /// sent, so a signed-in caller must not send them or the 422 lands on
  /// boxes the form is not showing.
  Future<bool> send({
    required String type,
    required String message,
    String? name,
    String? contact,
    String? reference,
  }) async {
    emit(
      state.copyWith(sending: true, fieldErrors: const {}, clearError: true),
    );

    final result = await _send(
      type: type,
      message: message,
      name: name,
      contact: contact,
      reference: reference,
      cancelToken: _cancel,
    );
    if (isClosed) return false;

    switch (result) {
      case Success(:final value):
        // Newest first, without a second request for a list we can
        // already write ourselves.
        emit(
          state.copyWith(
            items: [value, ...state.items],
            sending: false,
          ),
        );
        return true;
      case Failure(:final error):
        emit(
          state.copyWith(
            sending: false,
            fieldErrors: _fieldsOf(error),
            error: error is ValidationException ? null : error,
          ),
        );
        return false;
    }
  }

  /// The server's messages, keyed by the input each blames.
  static Map<String, String> _fieldsOf(AppException error) {
    if (error is! ValidationException) return const {};
    return {
      for (final field in ['type', 'message', 'name', 'contact', 'reference'])
        if (error.forField(field) case final said?) field: said,
    };
  }

  @override
  Future<void> close() {
    _cancel.cancel('complaints closed');
    return super.close();
  }
}
