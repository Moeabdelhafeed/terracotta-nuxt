import '../../../generated/l10n.dart';
import '../tr.dart';

/// HTTP status code display names. Consumed by
/// [core/constants/enums/api/api_status_code.dart].
class ApiStatusStrings {
  ApiStatusStrings._();

  static String get continueStatus =>
      Tr.t('api_status_continue', S.current.api_status_continue);
  static String get switchingProtocols => Tr.t(
    'api_status_switching_protocols',
    S.current.api_status_switching_protocols,
  );
  static String get processing =>
      Tr.t('api_status_processing', S.current.api_status_processing);
  static String get earlyHints =>
      Tr.t('api_status_early_hints', S.current.api_status_early_hints);
  static String get ok => Tr.t('api_status_ok', S.current.api_status_ok);
  static String get created =>
      Tr.t('api_status_created', S.current.api_status_created);
  static String get accepted =>
      Tr.t('api_status_accepted', S.current.api_status_accepted);
  static String get nonAuthoritativeInformation => Tr.t(
    'api_status_non_authoritative_information',
    S.current.api_status_non_authoritative_information,
  );
  static String get noContent =>
      Tr.t('api_status_no_content', S.current.api_status_no_content);
  static String get resetContent =>
      Tr.t('api_status_reset_content', S.current.api_status_reset_content);
  static String get partialContent =>
      Tr.t('api_status_partial_content', S.current.api_status_partial_content);
  static String get multiStatus =>
      Tr.t('api_status_multi_status', S.current.api_status_multi_status);
  static String get alreadyReported => Tr.t(
    'api_status_already_reported',
    S.current.api_status_already_reported,
  );
  static String get imUsed =>
      Tr.t('api_status_im_used', S.current.api_status_im_used);
  static String get multipleChoices => Tr.t(
    'api_status_multiple_choices',
    S.current.api_status_multiple_choices,
  );
  static String get movedPermanently => Tr.t(
    'api_status_moved_permanently',
    S.current.api_status_moved_permanently,
  );
  static String get found =>
      Tr.t('api_status_found', S.current.api_status_found);
  static String get seeOther =>
      Tr.t('api_status_see_other', S.current.api_status_see_other);
  static String get notModified =>
      Tr.t('api_status_not_modified', S.current.api_status_not_modified);
  static String get useProxy =>
      Tr.t('api_status_use_proxy', S.current.api_status_use_proxy);
  static String get temporaryRedirect => Tr.t(
    'api_status_temporary_redirect',
    S.current.api_status_temporary_redirect,
  );
  static String get permanentRedirect => Tr.t(
    'api_status_permanent_redirect',
    S.current.api_status_permanent_redirect,
  );
  static String get badRequest =>
      Tr.t('api_status_bad_request', S.current.api_status_bad_request);
  static String get unauthorized =>
      Tr.t('api_status_unauthorized', S.current.api_status_unauthorized);
  static String get paymentRequired => Tr.t(
    'api_status_payment_required',
    S.current.api_status_payment_required,
  );
  static String get forbidden =>
      Tr.t('api_status_forbidden', S.current.api_status_forbidden);
  static String get notFound =>
      Tr.t('api_status_not_found', S.current.api_status_not_found);
  static String get methodNotAllowed => Tr.t(
    'api_status_method_not_allowed',
    S.current.api_status_method_not_allowed,
  );
  static String get notAcceptable =>
      Tr.t('api_status_not_acceptable', S.current.api_status_not_acceptable);
  static String get proxyAuthenticationRequired => Tr.t(
    'api_status_proxy_authentication_required',
    S.current.api_status_proxy_authentication_required,
  );
  static String get requestTimeout =>
      Tr.t('api_status_request_timeout', S.current.api_status_request_timeout);
  static String get conflict =>
      Tr.t('api_status_conflict', S.current.api_status_conflict);
  static String get gone => Tr.t('api_status_gone', S.current.api_status_gone);
  static String get lengthRequired =>
      Tr.t('api_status_length_required', S.current.api_status_length_required);
  static String get preconditionFailed => Tr.t(
    'api_status_precondition_failed',
    S.current.api_status_precondition_failed,
  );
  static String get payloadTooLarge => Tr.t(
    'api_status_payload_too_large',
    S.current.api_status_payload_too_large,
  );
  static String get uriTooLong =>
      Tr.t('api_status_uri_too_long', S.current.api_status_uri_too_long);
  static String get unsupportedMediaType => Tr.t(
    'api_status_unsupported_media_type',
    S.current.api_status_unsupported_media_type,
  );
  static String get rangeNotSatisfiable => Tr.t(
    'api_status_range_not_satisfiable',
    S.current.api_status_range_not_satisfiable,
  );
  static String get expectationFailed => Tr.t(
    'api_status_expectation_failed',
    S.current.api_status_expectation_failed,
  );
  static String get misdirectedRequest => Tr.t(
    'api_status_misdirected_request',
    S.current.api_status_misdirected_request,
  );
  static String get validationError => Tr.t(
    'api_status_validation_error',
    S.current.api_status_validation_error,
  );
  static String get locked =>
      Tr.t('api_status_locked', S.current.api_status_locked);
  static String get failedDependency => Tr.t(
    'api_status_failed_dependency',
    S.current.api_status_failed_dependency,
  );
  static String get tooEarly =>
      Tr.t('api_status_too_early', S.current.api_status_too_early);
  static String get upgradeRequired => Tr.t(
    'api_status_upgrade_required',
    S.current.api_status_upgrade_required,
  );
  static String get preconditionRequired => Tr.t(
    'api_status_precondition_required',
    S.current.api_status_precondition_required,
  );
  static String get tooManyRequests => Tr.t(
    'api_status_too_many_requests',
    S.current.api_status_too_many_requests,
  );
  static String get requestHeaderFieldsTooLarge => Tr.t(
    'api_status_request_header_fields_too_large',
    S.current.api_status_request_header_fields_too_large,
  );
  static String get unavailableForLegalReasons => Tr.t(
    'api_status_unavailable_for_legal_reasons',
    S.current.api_status_unavailable_for_legal_reasons,
  );
  static String get internalServerError => Tr.t(
    'api_status_internal_server_error',
    S.current.api_status_internal_server_error,
  );
  static String get notImplemented =>
      Tr.t('api_status_not_implemented', S.current.api_status_not_implemented);
  static String get badGateway =>
      Tr.t('api_status_bad_gateway', S.current.api_status_bad_gateway);
  static String get serviceUnavailable => Tr.t(
    'api_status_service_unavailable',
    S.current.api_status_service_unavailable,
  );
  static String get gatewayTimeout =>
      Tr.t('api_status_gateway_timeout', S.current.api_status_gateway_timeout);
  static String get httpVersionNotSupported => Tr.t(
    'api_status_http_version_not_supported',
    S.current.api_status_http_version_not_supported,
  );
  static String get variantAlsoNegotiates => Tr.t(
    'api_status_variant_also_negotiates',
    S.current.api_status_variant_also_negotiates,
  );
  static String get insufficientStorage => Tr.t(
    'api_status_insufficient_storage',
    S.current.api_status_insufficient_storage,
  );
  static String get loopDetected =>
      Tr.t('api_status_loop_detected', S.current.api_status_loop_detected);
  static String get notExtended =>
      Tr.t('api_status_not_extended', S.current.api_status_not_extended);
  static String get networkAuthenticationRequired => Tr.t(
    'api_status_network_authentication_required',
    S.current.api_status_network_authentication_required,
  );
  static String get networkError =>
      Tr.t('api_status_network_error', S.current.api_status_network_error);
  static String get timeout =>
      Tr.t('api_status_timeout', S.current.api_status_timeout);
  static String get cancelled =>
      Tr.t('api_status_cancelled', S.current.api_status_cancelled);
  static String get unknownError =>
      Tr.t('api_status_unknown_error', S.current.api_status_unknown_error);
}
