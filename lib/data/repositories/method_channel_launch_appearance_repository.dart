import 'package:flutter/services.dart';
import 'package:ippo/data/repositories/launch_appearance_repository.dart';

/// Passes the launch brightness to the Android side (see MainActivity).
class MethodChannelLaunchAppearanceRepository
    implements LaunchAppearanceRepository {
  const MethodChannelLaunchAppearanceRepository([
    this._channel = const MethodChannel(channelName),
  ]);

  static const String channelName = 'ippo/launch_appearance';
  static const String method = 'setNightMode';

  final MethodChannel _channel;

  @override
  Future<void> setLaunchBrightness(LaunchBrightness brightness) async {
    try {
      await _channel.invokeMethod<void>(method, brightness.name);
    } on MissingPluginException {
      // No Android side: a test, or another platform.
    } on PlatformException {
      // The system refused; the launch screen follows the phone.
    }
  }
}
