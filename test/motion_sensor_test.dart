import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_charadas/utils/motion_sensor_service.dart';

void main() {
  group('MotionSensorService Tests', () {
    late MotionSensorService motionSensorService;

    setUp(() {
      motionSensorService = MotionSensorService();
    });

    test('should be singleton', () {
      final instance1 = MotionSensorService();
      final instance2 = MotionSensorService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('should start and stop correctly', () async {
      expect(motionSensorService.isActive, isFalse);
      
      await motionSensorService.start();
      expect(motionSensorService.isActive, isTrue);
      
      motionSensorService.stop();
      expect(motionSensorService.isActive, isFalse);
    });

    test('should return correct status', () {
      final status = motionSensorService.getStatus();
      expect(status['isActive'], isFalse);
      expect(status['canAnswer'], isTrue);
    });
  });
} 