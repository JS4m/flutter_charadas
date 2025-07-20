import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_charadas/utils/motion_sensor_service.dart';

void main() {
  group('MotionSensorService Tests', () {
    late MotionSensorService motionSensorService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      motionSensorService = MotionSensorService();
    });

    test('should be singleton', () {
      final instance1 = MotionSensorService();
      final instance2 = MotionSensorService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('should have correct initial state', () {
      expect(motionSensorService.isActive, isFalse);
      expect(motionSensorService.isOrientationLocked, isFalse);
    });

    test('should return correct status', () {
      final status = motionSensorService.getStatus();
      expect(status['isActive'], isFalse);
      expect(status['canAnswer'], isTrue);
      expect(status['isOrientationLocked'], isFalse);
    });

    test('should handle stop method', () {
      // Test that stop method can be called without throwing
      expect(() => motionSensorService.stop(), returnsNormally);
    });
  });
} 