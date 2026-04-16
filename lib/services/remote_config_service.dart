import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();

  factory RemoteConfigService() {
    return _instance;
  }

  RemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    _remoteConfig = FirebaseRemoteConfig.instance;

    // Set default values (fallback if Remote Config fails)
    await _remoteConfig.setDefaults({
      'active_exercise_color': 'FF1E40AF', // Default blue (red fallback: FFDC2626)
      'completed_exercise_color': 'FF1F2937', // Default grey
    });

    // Fetch and activate remote config
    try {
      await _remoteConfig.setMinimumFetchInterval(const Duration(hours: 1));
      await _remoteConfig.fetchAndActivate();
      print('[RemoteConfig] ✅ Successfully initialized and fetched config');
    } catch (e) {
      print('[RemoteConfig] ❌ Error fetching config: $e');
    }

    _initialized = true;
  }

  /// Get the active exercise color (when checkbox is ticked/selected)
  Color getActiveExerciseColor() {
    final colorHex = _remoteConfig.getString('active_exercise_color');
    return _hexToColor(colorHex);
  }

  /// Get the completed exercise color (when past)
  Color getCompletedExerciseColor() {
    final colorHex = _remoteConfig.getString('completed_exercise_color');
    return _hexToColor(colorHex);
  }

  /// Convert hex string to Color
  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (!hexString.startsWith('#') && !hexString.startsWith('FF')) {
        buffer.write('FF');
      }
      if (hexString.startsWith('#')) {
        hexString = hexString.substring(1);
        if (hexString.length == 6) {
          buffer.write('FF');
        }
      }
      buffer.write(hexString);
      return Color(int.parseUnsigned(buffer.toString(), radix: 16));
    } catch (e) {
      print('[RemoteConfig] ⚠️ Error parsing color $hexString: $e');
      return Colors.blue[700] ?? Colors.blue;
    }
  }
}
