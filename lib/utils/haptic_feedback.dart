import 'dart:io';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticUtils {
  /// Trigger haptic feedback for validation errors
  static Future<void> triggerValidationError() async {
    // Try HapticFeedback first (works better on iOS)
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      // Fallback to vibration package
      if (await Vibration.hasVibrator() ?? false) {
        if (Platform.isIOS) {
          Vibration.vibrate(pattern: [0, 100, 50, 100]); // Short pattern
        } else {
          Vibration.vibrate(duration: 80, amplitude: 25);
        }
      }
    }
  }

  /// Trigger haptic feedback for success actions
  static Future<void> triggerSuccess() async {
    try {
      HapticFeedback.lightImpact();
    } catch (e) {
      if (await Vibration.hasVibrator() ?? false) {
        if (Platform.isIOS) {
          Vibration.vibrate(pattern: [0, 50, 50, 50]); // Light pattern
        } else {
          Vibration.vibrate(duration: 50, amplitude: 15);
        }
      }
    }
  }

  /// Trigger haptic feedback for selection/button press
  static Future<void> triggerSelection() async {
    try {
      HapticFeedback.selectionClick();
    } catch (e) {
      if (await Vibration.hasVibrator() ?? false) {
        if (Platform.isIOS) {
          Vibration.vibrate(pattern: [0, 30]); // Very light
        } else {
          Vibration.vibrate(duration: 30, amplitude: 10);
        }
      }
    }
  }

  /// Trigger haptic feedback for heavy impact (errors, warnings)
  static Future<void> triggerHeavyImpact() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      if (await Vibration.hasVibrator() ?? false) {
        if (Platform.isIOS) {
          Vibration.vibrate(pattern: [0, 150, 100, 150]); // Stronger pattern
        } else {
          Vibration.vibrate(duration: 150, amplitude: 50);
        }
      }
    }
  }
} 