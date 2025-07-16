import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum DeviceOrientation {
  portraitUp,
  portraitDown,
  landscapeLeft,
  landscapeRight,
}

enum TiltDirection {
  neutral,
  up,    // Respuesta correcta
  down,  // Saltar palabra
}

class OrientationService {
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  DeviceOrientation _currentOrientation = DeviceOrientation.landscapeLeft;
  bool _isCalibrated = false;
  double _calibrationOffset = 0.0;
  
  // Callbacks
  Function(TiltDirection)? onTiltDetected;
  Function(DeviceOrientation)? onOrientationChanged;
  Function(String)? onError;
  
  // Configuración de sensibilidad
  static const double _tiltThreshold = 2.5;
  static const double _neutralZone = 0.5;
  static const double _maxTiltAngle = 10.0;
  static const int _calibrationSamples = 10;
  
  // Variables para calibración
  final List<double> _calibrationData = [];
  Timer? _calibrationTimer;
  
  bool get isActive => _gyroscopeSubscription != null || _accelerometerSubscription != null;
  bool get isCalibrated => _isCalibrated;
  DeviceOrientation get currentOrientation => _currentOrientation;

  /// Inicia el servicio de orientación con calibración automática
  Future<void> start({
    Function(TiltDirection)? onTilt,
    Function(DeviceOrientation)? onOrientationChange,
    Function(String)? onErrorCallback,
    bool autoCalibrate = true,
  }) async {
    onTiltDetected = onTilt;
    onOrientationChanged = onOrientationChange;
    onError = onErrorCallback;
    
    try {
      _startAccelerometer();
      _startGyroscope();
      
      if (autoCalibrate) {
        await _performCalibration();
      }
    } catch (e) {
      _handleError('Error al iniciar sensores: $e');
    }
  }

  /// Detiene todos los sensores y limpia recursos
  void stop() {
    _calibrationTimer?.cancel();
    _calibrationTimer = null;
    
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;
    
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    
    _isCalibrated = false;
    _calibrationOffset = 0.0;
    _calibrationData.clear();
  }

  /// Realiza calibración del giroscopio
  Future<void> _performCalibration() async {
    _isCalibrated = false;
    _calibrationData.clear();
    
    // Recopilar muestras para calibración
    final completer = Completer<void>();
    int sampleCount = 0;
    
    StreamSubscription<GyroscopeEvent>? calibrationSubscription;
    calibrationSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        if (sampleCount < _calibrationSamples) {
          _calibrationData.add(event.y);
          sampleCount++;
        } else {
          calibrationSubscription?.cancel();
          _calculateCalibrationOffset();
          _isCalibrated = true;
          completer.complete();
        }
      },
      onError: (error) {
        calibrationSubscription?.cancel();
        _handleError('Error durante calibración: $error');
        completer.completeError(error);
      },
    );
    
    // Timeout para calibración
    _calibrationTimer = Timer(const Duration(seconds: 3), () {
      if (!completer.isCompleted) {
        calibrationSubscription?.cancel();
        _calculateCalibrationOffset();
        _isCalibrated = true;
        completer.complete();
      }
    });
    
    await completer.future;
  }

  /// Calcula el offset de calibración
  void _calculateCalibrationOffset() {
    if (_calibrationData.isEmpty) {
      _calibrationOffset = 0.0;
      return;
    }
    
    // Calcular promedio de las muestras de calibración
    double sum = _calibrationData.reduce((a, b) => a + b);
    _calibrationOffset = sum / _calibrationData.length;
    
    // Limitar el offset para evitar valores extremos
    _calibrationOffset = _calibrationOffset.clamp(-2.0, 2.0);
  }

  /// Inicia el acelerómetro para detectar orientación
  void _startAccelerometer() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        _updateOrientation(event);
      },
      onError: (error) {
        _handleError('Error en acelerómetro: $error');
      },
    );
  }

  /// Inicia el giroscopio para detectar inclinación
  void _startGyroscope() {
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        if (_isCalibrated) {
          _processTiltEvent(event);
        }
      },
      onError: (error) {
        _handleError('Error en giroscopio: $error');
      },
    );
  }

  /// Actualiza la orientación basándose en el acelerómetro
  void _updateOrientation(AccelerometerEvent event) {
    DeviceOrientation newOrientation;
    
    // Determinar orientación basándose en la gravedad
    double x = event.x;
    double y = event.y;
    double z = event.z;
    
    // Calcular ángulos
    double roll = math.atan2(y, z) * (180.0 / math.pi);
    double pitch = math.atan2(-x, math.sqrt(y * y + z * z)) * (180.0 / math.pi);
    
    // Determinar orientación con histéresis para evitar oscilaciones
    if (roll.abs() < 45) {
      newOrientation = pitch > 0 ? DeviceOrientation.portraitDown : DeviceOrientation.portraitUp;
    } else {
      newOrientation = roll > 0 ? DeviceOrientation.landscapeRight : DeviceOrientation.landscapeLeft;
    }
    
    // Solo notificar si cambió la orientación
    if (newOrientation != _currentOrientation) {
      _currentOrientation = newOrientation;
      onOrientationChanged?.call(_currentOrientation);
    }
  }

  /// Procesa eventos de inclinación del giroscopio
  void _processTiltEvent(GyroscopeEvent event) {
    // Aplicar calibración
    double adjustedY = event.y - _calibrationOffset;
    
    // Aplicar corrección de orientación
    double correctedTilt = _applyCorrectionForOrientation(adjustedY);
    
    // Limitar ángulo para evitar valores extremos
    correctedTilt = correctedTilt.clamp(-_maxTiltAngle, _maxTiltAngle);
    
    // Determinar dirección de inclinación
    TiltDirection direction = _calculateTiltDirection(correctedTilt);
    
    // Notificar cambio de inclinación
    onTiltDetected?.call(direction);
  }

  /// Aplica corrección basada en la orientación actual del dispositivo
  double _applyCorrectionForOrientation(double tiltValue) {
    switch (_currentOrientation) {
      case DeviceOrientation.landscapeLeft:
        return tiltValue; // Sin corrección
      case DeviceOrientation.landscapeRight:
        return -tiltValue; // Invertir
      case DeviceOrientation.portraitUp:
      case DeviceOrientation.portraitDown:
        // En modo portrait, usar otro eje (esto normalmente no debería pasar en el juego)
        return tiltValue;
    }
  }

  /// Calcula la dirección de inclinación
  TiltDirection _calculateTiltDirection(double tiltValue) {
    if (tiltValue > _tiltThreshold) {
      return TiltDirection.up; // Respuesta correcta
    } else if (tiltValue < -_tiltThreshold) {
      return TiltDirection.down; // Saltar palabra
    } else if (tiltValue.abs() <= _neutralZone) {
      return TiltDirection.neutral; // Zona neutral
    } else {
      // En zona intermedia, mantener estado anterior
      return TiltDirection.neutral;
    }
  }

  /// Maneja errores del servicio
  void _handleError(String errorMessage) {
    if (kDebugMode) {
      print('OrientationService Error: $errorMessage');
    }
    onError?.call(errorMessage);
  }

  /// Recalibra manualmente el giroscopio
  Future<void> recalibrate() async {
    await _performCalibration();
  }

  /// Obtiene el estado actual del servicio como mapa
  Map<String, dynamic> getStatus() {
    return {
      'isActive': isActive,
      'isCalibrated': isCalibrated,
      'currentOrientation': _currentOrientation.toString(),
      'calibrationOffset': _calibrationOffset,
      'calibrationSamples': _calibrationData.length,
    };
  }
} 