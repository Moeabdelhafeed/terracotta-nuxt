// Project imports:
import '../../../localization/strings/api_status_strings.dart';

enum ApiStatusCode {
  // 1xx Informational
  continueStatus(
    100,
    true,
    Duration(milliseconds: 100),
  ),
  switchingProtocols(
    101,
    true,
    Duration(milliseconds: 100),
  ),
  processing(
    102,
    true,
    Duration(milliseconds: 100),
  ),
  earlyHints(
    103,
    true,
    Duration(milliseconds: 100),
  ),

  // 2xx Success
  ok(
    200,
    false,
    Duration(seconds: 0),
  ),
  created(
    201,
    false,
    Duration(seconds: 0),
  ),
  accepted(
    202,
    true,
    Duration(milliseconds: 500),
  ),
  nonAuthoritativeInformation(
    203,
    true,
    Duration(milliseconds: 200),
  ),
  noContent(
    204,
    false,
    Duration(seconds: 0),
  ),
  resetContent(
    205,
    true,
    Duration(milliseconds: 200),
  ),
  partialContent(
    206,
    true,
    Duration(milliseconds: 200),
  ),
  multiStatus(
    207,
    true,
    Duration(milliseconds: 200),
  ),
  alreadyReported(
    208,
    true,
    Duration(milliseconds: 100),
  ),
  imUsed(
    226,
    true,
    Duration(milliseconds: 100),
  ),

  // 3xx Redirection
  multipleChoices(
    300,
    true,
    Duration(milliseconds: 200),
  ),
  movedPermanently(
    301,
    true,
    Duration(milliseconds: 500),
  ),
  found(
    302,
    true,
    Duration(milliseconds: 500),
  ),
  seeOther(
    303,
    true,
    Duration(milliseconds: 200),
  ),
  notModified(
    304,
    false,
    Duration(seconds: 0),
  ),
  useProxy(
    305,
    true,
    Duration(milliseconds: 500),
  ),
  temporaryRedirect(
    307,
    true,
    Duration(milliseconds: 500),
  ),
  permanentRedirect(
    308,
    true,
    Duration(milliseconds: 500),
  ),

  // 4xx Client Errors
  badRequest(
    400,
    true,
    Duration(seconds: 1),
  ),
  unauthorized(
    401,
    true,
    Duration(seconds: 1),
  ),
  paymentRequired(
    402,
    true,
    Duration(seconds: 1),
  ),
  forbidden(
    403,
    true,
    Duration(seconds: 1),
  ),
  notFound(
    404,
    true,
    Duration(seconds: 1),
  ),
  notAllowed(
    405,
    true,
    Duration(seconds: 1),
  ),
  notAcceptable(
    406,
    true,
    Duration(seconds: 1),
  ),
  proxyAuthenticationRequired(
    407,
    true,
    Duration(seconds: 1),
  ),
  requestTimeout(
    408,
    true,
    Duration(seconds: 1),
  ),
  conflict(
    409,
    true,
    Duration(seconds: 1),
  ),
  gone(
    410,
    true,
    Duration(seconds: 1),
  ),
  lengthRequired(
    411,
    true,
    Duration(seconds: 1),
  ),
  preconditionFailed(
    412,
    true,
    Duration(seconds: 1),
  ),
  payloadTooLarge(
    413,
    true,
    Duration(seconds: 1),
  ),
  uriTooLong(
    414,
    true,
    Duration(seconds: 1),
  ),
  unsupportedMediaType(
    415,
    true,
    Duration(seconds: 1),
  ),
  rangeNotSatisfiable(
    416,
    true,
    Duration(seconds: 1),
  ),
  expectationFailed(
    417,
    true,
    Duration(seconds: 1),
  ),
  misdirectedRequest(
    421,
    true,
    Duration(seconds: 1),
  ),
  validation(
    422,
    true,
    Duration(seconds: 1),
  ),
  locked(
    423,
    true,
    Duration(seconds: 1),
  ),
  failedDependency(
    424,
    true,
    Duration(seconds: 1),
  ),
  tooEarly(
    425,
    true,
    Duration(seconds: 1),
  ),
  upgradeRequired(
    426,
    true,
    Duration(seconds: 1),
  ),
  preconditionRequired(
    428,
    true,
    Duration(seconds: 1),
  ),
  rateLimited(
    429,
    true,
    Duration(seconds: 1),
  ),
  requestHeaderFieldsTooLarge(
    431,
    true,
    Duration(seconds: 1),
  ),
  unavailableForLegalReasons(
    451,
    true,
    Duration(seconds: 1),
  ),

  // 5xx Server Errors
  server(
    500,
    true,
    Duration(seconds: 1),
  ),
  notImplemented(
    501,
    true,
    Duration(seconds: 1),
  ),
  badGateway(
    502,
    true,
    Duration(seconds: 1),
  ),
  serviceUnavailable(
    503,
    true,
    Duration(seconds: 2),
  ),
  gatewayTimeout(
    504,
    true,
    Duration(seconds: 2),
  ),
  httpVersionNotSupported(
    505,
    true,
    Duration(seconds: 1),
  ),
  variantAlsoNegotiates(
    506,
    true,
    Duration(seconds: 1),
  ),
  insufficientStorage(
    507,
    true,
    Duration(seconds: 1),
  ),
  loopDetected(
    508,
    true,
    Duration(seconds: 1),
  ),
  notExtended(
    510,
    true,
    Duration(seconds: 1),
  ),
  networkAuthenticationRequired(
    511,
    true,
    Duration(seconds: 1),
  ),

  // Custom/Non-standard/Network/Timeout/Unknown
  network(
    -1,
    true,
    Duration(seconds: 1),
  ),
  timeout(
    -2,
    true,
    Duration(seconds: 1),
  ),
  cancelled(
    -3,
    true,
    Duration(seconds: 1),
  ),
  unknown(
    -999,
    true,
    Duration(seconds: 1),
  );

  const ApiStatusCode(
    this._code,
    this._isRecoverable,
    this._retryDelay,
  );

  final int _code;
  final bool _isRecoverable;
  final Duration _retryDelay;

  int get code => _code;

  /// The three surface strings (title / description / userMessage) all
  /// resolve to the same localized label today. If product ever needs
  /// them to diverge, split this helper.
  String get _label => switch (this) {
    .continueStatus => ApiStatusStrings.continueStatus,
    .switchingProtocols => ApiStatusStrings.switchingProtocols,
    .processing => ApiStatusStrings.processing,
    .earlyHints => ApiStatusStrings.earlyHints,
    .ok => ApiStatusStrings.ok,
    .created => ApiStatusStrings.created,
    .accepted => ApiStatusStrings.accepted,
    .nonAuthoritativeInformation =>
      ApiStatusStrings.nonAuthoritativeInformation,
    .noContent => ApiStatusStrings.noContent,
    .resetContent => ApiStatusStrings.resetContent,
    .partialContent => ApiStatusStrings.partialContent,
    .multiStatus => ApiStatusStrings.multiStatus,
    .alreadyReported => ApiStatusStrings.alreadyReported,
    .imUsed => ApiStatusStrings.imUsed,
    .multipleChoices => ApiStatusStrings.multipleChoices,
    .movedPermanently => ApiStatusStrings.movedPermanently,
    .found => ApiStatusStrings.found,
    .seeOther => ApiStatusStrings.seeOther,
    .notModified => ApiStatusStrings.notModified,
    .useProxy => ApiStatusStrings.useProxy,
    .temporaryRedirect => ApiStatusStrings.temporaryRedirect,
    .permanentRedirect => ApiStatusStrings.permanentRedirect,
    .badRequest => ApiStatusStrings.badRequest,
    .unauthorized => ApiStatusStrings.unauthorized,
    .paymentRequired => ApiStatusStrings.paymentRequired,
    .forbidden => ApiStatusStrings.forbidden,
    .notFound => ApiStatusStrings.notFound,
    .notAllowed => ApiStatusStrings.methodNotAllowed,
    .notAcceptable => ApiStatusStrings.notAcceptable,
    .proxyAuthenticationRequired =>
      ApiStatusStrings.proxyAuthenticationRequired,
    .requestTimeout => ApiStatusStrings.requestTimeout,
    .conflict => ApiStatusStrings.conflict,
    .gone => ApiStatusStrings.gone,
    .lengthRequired => ApiStatusStrings.lengthRequired,
    .preconditionFailed => ApiStatusStrings.preconditionFailed,
    .payloadTooLarge => ApiStatusStrings.payloadTooLarge,
    .uriTooLong => ApiStatusStrings.uriTooLong,
    .unsupportedMediaType => ApiStatusStrings.unsupportedMediaType,
    .rangeNotSatisfiable => ApiStatusStrings.rangeNotSatisfiable,
    .expectationFailed => ApiStatusStrings.expectationFailed,
    .misdirectedRequest => ApiStatusStrings.misdirectedRequest,
    .validation => ApiStatusStrings.validationError,
    .locked => ApiStatusStrings.locked,
    .failedDependency => ApiStatusStrings.failedDependency,
    .tooEarly => ApiStatusStrings.tooEarly,
    .upgradeRequired => ApiStatusStrings.upgradeRequired,
    .preconditionRequired => ApiStatusStrings.preconditionRequired,
    .rateLimited => ApiStatusStrings.tooManyRequests,
    .requestHeaderFieldsTooLarge =>
      ApiStatusStrings.requestHeaderFieldsTooLarge,
    .unavailableForLegalReasons => ApiStatusStrings.unavailableForLegalReasons,
    .server => ApiStatusStrings.internalServerError,
    .notImplemented => ApiStatusStrings.notImplemented,
    .badGateway => ApiStatusStrings.badGateway,
    .serviceUnavailable => ApiStatusStrings.serviceUnavailable,
    .gatewayTimeout => ApiStatusStrings.gatewayTimeout,
    .httpVersionNotSupported => ApiStatusStrings.httpVersionNotSupported,
    .variantAlsoNegotiates => ApiStatusStrings.variantAlsoNegotiates,
    .insufficientStorage => ApiStatusStrings.insufficientStorage,
    .loopDetected => ApiStatusStrings.loopDetected,
    .notExtended => ApiStatusStrings.notExtended,
    .networkAuthenticationRequired =>
      ApiStatusStrings.networkAuthenticationRequired,
    .network => ApiStatusStrings.networkError,
    .timeout => ApiStatusStrings.timeout,
    .cancelled => ApiStatusStrings.cancelled,
    .unknown => ApiStatusStrings.unknownError,
  };

  String get title => _label;
  String get description => _label;
  String get userMessage => _label;

  bool get isRecoverable => _isRecoverable;
  Duration get retryDelay => _retryDelay;

  bool get isInformational => _code >= 100 && _code < 200;
  bool get isSuccess => _code >= 200 && _code < 300;
  bool get isRedirection => _code >= 300 && _code < 400;
  bool get isClientError => _code >= 400 && _code < 500;
  bool get isServerError => _code >= 500 && _code < 600;
  bool get isNetworkError => _code < 0;

  static ApiStatusCode fromStatusCode(int statusCode) =>
      ApiStatusCode.values.firstWhere(
        (errorType) => errorType.code == statusCode,
        orElse: () => ApiStatusCode.unknown,
      );
}
