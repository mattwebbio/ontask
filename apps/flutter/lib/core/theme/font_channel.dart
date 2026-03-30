import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('com.ontaskhq.ontask/fonts');

/// Queries the iOS platform to determine if the New York serif font is
/// available on the current device.
///
/// Returns `false` on all non-iOS platforms (macOS uses Playfair Display
/// fallback in this story; macOS New York support is deferred).
///
/// Catches [PlatformException] and returns `false` as a safe fallback.
Future<bool> isNewYorkAvailable() async {
  if (!Platform.isIOS) return false;
  try {
    return await _channel.invokeMethod<bool>('isNewYorkAvailable') ?? false;
  } on PlatformException {
    return false;
  }
}
