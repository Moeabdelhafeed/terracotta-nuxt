import 'package:freezed_annotation/freezed_annotation.dart';

import 'device_session.dart';

part 'device_list.freezed.dart';
part 'device_list.g.dart';

/// `GET /api/devices` — the wrapper around the device rows.
///
/// The payload is `{"devices": [...]}`, not a bare array, so the list
/// cannot be read with `getList`.
@freezed
abstract class DeviceList with _$DeviceList {
  const factory DeviceList({
    @Default(<DeviceSession>[]) List<DeviceSession> devices,
  }) = _DeviceList;

  const DeviceList._();

  factory DeviceList.fromJson(Map<String, dynamic> json) =>
      _$DeviceListFromJson(json);

  /// The device this app is running on, if the server flagged one.
  DeviceSession? get current => devices.where((d) => d.isCurrent).firstOrNull;
}
