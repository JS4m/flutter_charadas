import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum TiltDirection {  
  neutral,
  up,    // Respuesta correcta - VERDE
  down,  // Saltar palabra - ROJO
}

class MotionSensorService {
  static final MotionSensorService _instance = MotionSensorService._internal();
  factory MotionSensorService() => _instance;
  MotionSensorService._internal();

  // Stream del giroscopio
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  // Callbacks
  Function(TiltDirection)? onTiltDetected;
  Function(String)? onError;
  
  // Estado interno
  bool _isActive = false;
  bool _canAnswer = true;
  bool _isOrientationLocked = false;

  bool get isActive => _isActive;
  bool get isOrientationLocked => _isOrientationLocked;

  /// Inicia el servicio de sensores usando la lógica directa del giroscopio
  Future<void> start({
    Function(TiltDirection)? onTilt,
    Function(String)? onErrorCallback,
  }) async {
    if (_isActive) return;
    
    onTiltDetected = onTilt;
    onError = onErrorCallback;
    
    try {
      _isActive = true;
      _canAnswer = true;
      
      // Iniciar sensor de giroscopio (la orientación ya está bloqueada por GameScreen)
      _startGyroscope();
      
      debugPrint('[MotionSensorService] Servicio iniciado correctamente');
    } catch (e) {
      _handleError('Error al iniciar sensores: $e');
      rethrow;
    }
  }

  /// Detiene todos los sensores y limpia recursos
  void stop() {
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;
    
    _isActive = false;
    _canAnswer = false;
    
    // No desbloquear orientación aquí - lo maneja GameScreen
    debugPrint('[MotionSensorService] Servicio detenido');
  }

  /// Bloquea la orientación horizontal
  Future<void> _lockHorizontalOrientation() async {
    try {
      // Verificar si ya está bloqueada para evitar conflictos
      if (_isOrientationLocked) {
        debugPrint('[MotionSensorService] Orientación ya bloqueada, saltando...');
        return;
      }
      
      // Bloquear solo orientaciones horizontales
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      _isOrientationLocked = true;
      debugPrint('[MotionSensorService] Orientación horizontal bloqueada');
    } catch (e) {
      _handleError('Error bloqueando orientación: $e');
    }
  }

  /// Desbloquea la orientación
  void _unlockOrientation() {
    try {
      // Permitir todas las orientaciones
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      _isOrientationLocked = false;
      debugPrint('[MotionSensorService] Orientación desbloqueada');
    } catch (e) {
      _handleError('Error desbloqueando orientación: $e');
    }
  }

  /// Inicia el sensor de giroscopio usando la lógica exacta del ejemplo
  void _startGyroscope() {
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        _processGyroscopeEvent(event);
      },
      onError: (error) {
        _handleError('Error en giroscopio: $error');
      },
    );
  }

  /// Procesa eventos del giroscopio usando exactamente la lógica del ejemplo
  void _processGyroscopeEvent(GyroscopeEvent event) {
    if (!_isActive || !_canAnswer) {
      return;
    }

    // Usar exactamente la misma lógica del ejemplo
    if (event.y > 2.5) {
      // Respuesta correcta - VERDE
      _canAnswer = false;
      onTiltDetected?.call(TiltDirection.up);
      debugPrint('[MotionSensorService] Tilt UP detectado (Y: ${event.y.toStringAsFixed(2)})');
      
      // Resetear después de 1 segundo como en el ejemplo
      Timer(const Duration(seconds: 1), () {
        if (_isActive) {
          _canAnswer = true;
        }
      });
      
    } else if (event.y < -2.5) {
      // Saltar palabra - ROJO
      _canAnswer = false;
      onTiltDetected?.call(TiltDirection.down);
      debugPrint('[MotionSensorService] Tilt DOWN detectado (Y: ${event.y.toStringAsFixed(2)})');
      
      // Resetear después de 1 segundo como en el ejemplo
      Timer(const Duration(seconds: 1), () {
        if (_isActive) {
          _canAnswer = true;
        }
      });
      
    } else if (event.y >= -0.5 && event.y <= 0.5) {
      // Zona neutral
      onTiltDetected?.call(TiltDirection.neutral);
    }
  }

  /// Maneja errores del servicio
  void _handleError(String errorMessage) {
    debugPrint('[MotionSensorService] Error: $errorMessage');
    onError?.call(errorMessage);
  }

  /// Obtiene el estado actual del servicio
  Map<String, dynamic> getStatus() {
    return {
      'isActive': _isActive,
      'canAnswer': _canAnswer,
      'isOrientationLocked': _isOrientationLocked,
    };
  }
}