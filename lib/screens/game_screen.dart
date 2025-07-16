import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/game_state.dart';
import '../models/game_state_model.dart';
import '../widgets/celebration_animation.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _restored = false; // Flag para evitar restauraciones dobles

  @override
  void initState() {
    super.initState();
    // Forzar orientación horizontal al entrar al juego (incluyendo countdown)
    _lockHorizontalOrientation();
    
    // Ocultar barras del sistema para experiencia completa
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Iniciar la cuenta regresiva cuando se crea la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // CRÍTICO: Verificar que el widget sigue montado antes de disparar eventos
      if (mounted) {
        context.read<GameBloc>().add(StartCountdownEvent());
      }
    });
  }

  /// Bloquea la orientación horizontal
  Future<void> _lockHorizontalOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      debugPrint('[GameScreen] Orientación horizontal bloqueada desde initState');
    } catch (e) {
      debugPrint('[GameScreen] Error bloqueando orientación: $e');
    }
  }

  @override
  void dispose() {
    // Restaurar solo si no se restauró antes
    if (!_restored) {
      debugPrint('[GameScreen] Restauración forzada en dispose');
      _restoreEnvironment();
      _restored = true;
    }
    super.dispose();
  }

  Future<void> _restoreEnvironment() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await Future.delayed(const Duration(milliseconds: 100));
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      debugPrint('[GameScreen] Entorno restaurado correctamente');
    } catch (e) {
      debugPrint('[GameScreen] Error restaurando entorno: $e');
    }
  }

  // Función helper para obtener tamaños responsivos
  double _getResponsiveFontSize(BuildContext context, double baseSize, {bool isLandscape = true}) {
    final screenSize = MediaQuery.of(context).size;
    final minDimension = isLandscape ? screenSize.height : screenSize.width;
    
    // Escalar basándose en la dimensión mínima
    double scaleFactor = minDimension / (isLandscape ? 400 : 600);
    scaleFactor = scaleFactor.clamp(0.7, 1.3); // Limitar el factor de escala
    
    return (baseSize * scaleFactor).clamp(12.0, baseSize * 1.5);
  }

  // Función helper para obtener padding responsivo
  EdgeInsets _getResponsivePadding(BuildContext context, {bool isLandscape = true}) {
    final screenSize = MediaQuery.of(context).size;
    final minDimension = isLandscape ? screenSize.height : screenSize.width;
    
    double basePadding = minDimension * 0.02;
    basePadding = basePadding.clamp(8.0, 24.0);
    
    return EdgeInsets.all(basePadding);
  }

  @override
  Widget build(BuildContext context) {
    // Quitar el Scaffold interior - el padre (HomeScreen) maneja el Scaffold
    return WillPopScope(
      onWillPop: () async {
        debugPrint('[GameScreen] onWillPop interceptado');
        await _exitGame(context);
        return false;
      },
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
            return BlocBuilder<GameBloc, GameState>(
              builder: (context, state) {
                if (state is GameCountdown) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenSize.height * 0.7,
                        maxHeight: screenSize.height,
                      ),
                      child: _buildCountdownScreen(context, state.gameState, isLandscape, screenSize),
                    ),
                  );
                }
                if (state is GamePlaying) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenSize.height * 0.7,
                        maxHeight: screenSize.height,
                      ),
                      child: _buildGameScreen(context, state.gameState, isLandscape, screenSize),
                    ),
                  );
                }
                if (state is GamePaused) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenSize.height * 0.7,
                        maxHeight: screenSize.height,
                      ),
                      child: _buildPauseScreen(context, state.gameState, isLandscape, screenSize),
                    ),
                  );
                }
                if (state is GameOver) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenSize.height * 0.7,
                        maxHeight: screenSize.height,
                      ),
                      child: _buildGameOverScreen(context, state.gameState, isLandscape, screenSize),
                    ),
                  );
                }
                return _buildLoadingScreen();
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _exitGame(BuildContext context) async {
    if (_restored) {
      debugPrint('[GameScreen] _exitGame llamado pero ya restaurado');
      return;
    }
    debugPrint('[GameScreen] _exitGame inicia restauración');
    _restored = true;
    final currentState = context.read<GameBloc>().state;
    
    // Capturar todas las referencias del contexto ANTES de cualquier operación async
    final gameBloc = context.read<GameBloc>();
    
    // Restaurar orientaciones de forma gradual para evitar desbordamiento
    await _restoreEnvironment();
    
    // Verificar que el widget sigue montado antes de usar las referencias capturadas
    if (!mounted) return;
    
    // Manejar la salida según el estado actual
    if (currentState is GameCountdown) {
      // Cancelar el countdown inmediatamente
      gameBloc.add(CancelCountdownEvent());
      
      // Pequeño delay para que se procese el evento
      await Future.delayed(const Duration(milliseconds: 50));
    } else {
      // Para otros estados (playing, paused, gameOver)
      // Resetear el juego y volver
      gameBloc.add(ResetGameEvent());
      
      // Pequeño delay para que se procese el reset
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    // Ahora usar Navigator.pop() para desmontar la pantalla de juego limpiamente
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: const Color(0xFF1D4ED8),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildCountdownScreen(BuildContext context, GameStateModel gameState, bool isLandscape, Size screenSize) {
    return Container(
      color: const Color(0xFFFBBF24),
      child: SafeArea(
        child: Stack(
          children: [
            // Botón de cerrar (X) - Responsivo
            Positioned(
              top: screenSize.height * 0.02,
              left: screenSize.width * 0.02,
              child: GestureDetector(
                onTap: () => _exitGame(context),
                child: Container(
                  padding: EdgeInsets.all(screenSize.height * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(screenSize.height * 0.02),
                  ),
                  child: Icon(
                    Icons.close, 
                    color: Colors.white, 
                    size: _getResponsiveFontSize(context, 24, isLandscape: isLandscape)
                  ),
                ),
              ),
            ),
            // Contenido central - Responsivo
            Center(
              child: Padding(
                padding: _getResponsivePadding(context, isLandscape: isLandscape),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'PREPARARSE!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _getResponsiveFontSize(context, 48, isLandscape: isLandscape),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          decoration: TextDecoration.none,
                          decorationColor: Colors.transparent,
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.05),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'El juego comenzará en: ${gameState.countdown}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _getResponsiveFontSize(context, 28, isLandscape: isLandscape),
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.none,
                          decorationColor: Colors.transparent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen(BuildContext context, GameStateModel gameState, bool isLandscape, Size screenSize) {
    Color backgroundColor = _getBackgroundColor(gameState.tiltAngle);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: backgroundColor,
      child: SafeArea(
        child: Stack(
          children: [
            // Botón de cerrar (X) - Responsivo
            Positioned(
              top: screenSize.height * 0.015,
              left: screenSize.width * 0.015,
              child: GestureDetector(
                onTap: () => _exitGame(context),
                child: Container(
                  padding: EdgeInsets.all(screenSize.height * 0.01),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(screenSize.height * 0.015),
                  ),
                  child: Icon(
                    Icons.close, 
                    color: Colors.white, 
                    size: _getResponsiveFontSize(context, 20, isLandscape: isLandscape)
                  ),
                ),
              ),
            ),
            // Botón de pausa - Responsivo
            Positioned(
              top: screenSize.height * 0.015,
              right: screenSize.width * 0.015,
              child: GestureDetector(
                onTap: () {
                  context.read<GameBloc>().add(PauseGameEvent());
                },
                child: Container(
                  padding: EdgeInsets.all(screenSize.height * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(screenSize.height * 0.015),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: screenSize.height * 0.008,
                        height: screenSize.height * 0.04,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      SizedBox(width: screenSize.height * 0.01),
                      Container(
                        width: screenSize.height * 0.008,
                        height: screenSize.height * 0.04,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Temporizador grande arriba - Responsivo
            Positioned(
              top: screenSize.height * 0.08,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${gameState.timer}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context, 48, isLandscape: isLandscape),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                    shadows: const [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black26,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Palabra grande y centrada - Con protección contra overflow
            Center(
              child: AnimatedScale(
                scale: gameState.canAnswer ? 1.0 : 0.8,
                duration: const Duration(milliseconds: 200),
                child: AnimatedOpacity(
                  opacity: gameState.canAnswer ? 1.0 : 0.7,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: screenSize.width * 0.85,
                      maxHeight: screenSize.height * 0.4,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        gameState.currentWord,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 56, isLandscape: isLandscape),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                          decoration: TextDecoration.none,
                          decorationColor: Colors.transparent,
                          shadows: const [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black26,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Score - Responsivo
            Positioned(
              top: screenSize.height * 0.18,
              left: screenSize.width * 0.015,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.02, 
                  vertical: screenSize.height * 0.01
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(screenSize.height * 0.015),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Puntos: ${gameState.score}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _getResponsiveFontSize(context, 16, isLandscape: isLandscape),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseScreen(BuildContext context, GameStateModel gameState, bool isLandscape, Size screenSize) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E3A8A), // Azul más oscuro arriba
            Color(0xFF1D4ED8), // Azul medio abajo
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenSize.width * 0.8,
              maxHeight: screenSize.height * 0.9,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título PAUSADO - Responsivo
                FittedBox(
                  fit: BoxFit.scaleDown,
                                      child: Text(
                      'Pausado',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 64, isLandscape: isLandscape),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                      ),
                    ),
                ),
                
                SizedBox(height: screenSize.height * 0.1),
                
                // Botón Continuar - Responsivo
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: screenSize.width * 0.6,
                    minHeight: screenSize.height * 0.08,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      context.read<GameBloc>().add(ResumeGameEvent());
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: _getResponsiveFontSize(context, 32, isLandscape: isLandscape),
                          ),
                          SizedBox(width: screenSize.width * 0.02),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'CONTINUAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _getResponsiveFontSize(context, 24, isLandscape: isLandscape),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                decoration: TextDecoration.none,
                                decorationColor: Colors.transparent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: screenSize.height * 0.04),
                
                // Botón Salir del juego - Responsivo
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: screenSize.width * 0.6,
                    minHeight: screenSize.height * 0.08,
                  ),
                  child: GestureDetector(
                    onTap: () => _exitGame(context),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.close,
                            color: Colors.white,
                            size: _getResponsiveFontSize(context, 32, isLandscape: isLandscape),
                          ),
                          SizedBox(width: screenSize.width * 0.02),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                                                              child: Text(
                                  'SALIR DEL JUEGO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _getResponsiveFontSize(context, 24, isLandscape: isLandscape),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    decoration: TextDecoration.none,
                                    decorationColor: Colors.transparent,
                                  ),
                                ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverScreen(BuildContext context, GameStateModel gameState, bool isLandscape, Size screenSize) {
    return Container(
      color: const Color(0xFF1D4ED8),
      child: SafeArea(
        child: Stack(
          children: [
            // Animación de celebración
            const Positioned.fill(
              child: CelebrationAnimation(),
            ),
            // Botón de cerrar (X) - Responsivo
            Positioned(
              top: screenSize.height * 0.02,
              left: screenSize.width * 0.02,
              child: GestureDetector(
                onTap: () => _exitGame(context),
                child: Container(
                  padding: EdgeInsets.all(screenSize.height * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(screenSize.height * 0.02),
                  ),
                  child: Icon(
                    Icons.close, 
                    color: Colors.white, 
                    size: _getResponsiveFontSize(context, 32, isLandscape: isLandscape)
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenSize.width * 0.8,
                  maxHeight: screenSize.height * 0.9,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                                              child: Text(
                          '¡Juego terminado!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _getResponsiveFontSize(context, 40, isLandscape: isLandscape),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            decoration: TextDecoration.none,
                            decorationColor: Colors.transparent,
                          ),
                        ),
                    ),
                    SizedBox(height: screenSize.height * 0.05),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                                              child: Text(
                          'Puntaje: ${gameState.score}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _getResponsiveFontSize(context, 56, isLandscape: isLandscape),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                            decorationColor: Colors.transparent,
                          ),
                        ),
                    ),
                    SizedBox(height: screenSize.height * 0.08),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: screenSize.width * 0.7,
                        minHeight: screenSize.height * 0.08,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1D4ED8),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenSize.width * 0.06, 
                              vertical: screenSize.height * 0.02
                            ),
                            textStyle: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 24, isLandscape: isLandscape), 
                              fontWeight: FontWeight.bold
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            // Mantener orientación horizontal para el reinicio
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.landscapeRight,
                            ]);
                            
                            // Ocultar barras del sistema para el reinicio
                            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                            
                            context.read<GameBloc>().add(RestartGameEvent());
                          },
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: const Text('Jugar de nuevo')
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(double tiltAngle) {
    // Cuando tiltAngle es positivo (90.0) = CORRECTO = VERDE
    if (tiltAngle > 45) {
      return Colors.green; // Correcto - UP
    // Cuando tiltAngle es negativo (-90.0) = SALTAR = ROJO  
    } else if (tiltAngle < -45) {
      return Colors.red; // Saltar - DOWN
    } else {
      return const Color(0xFF1D4ED8); // Normal (azul)
    }
  }
} 