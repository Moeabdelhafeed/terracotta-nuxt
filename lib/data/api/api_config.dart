// Project imports:
import '../services/remote_config_service.dart';

class BaseApiConstants {
  const BaseApiConstants._();

  static String get baseUrl => RemoteConfigService.baseUrl;

  static const String apiVersion = '/v1';
}
