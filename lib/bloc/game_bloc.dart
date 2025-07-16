import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/category_repository.dart';
import '../models/game_state_model.dart';
import '../utils/motion_sensor_service.dart';
import 'game_event.dart';
import 'game_state.dart';
import 'package:hive/hive.dart';
import '../models/word_category.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final CategoryRepository _categoryRepository;
  final MotionSensorService _motionSensorService = MotionSensorService();
  Timer? _countdownTimer;
  Timer? _gameTimer;
  bool _isDisposed = false;
  Box? _hiveBox;
  
  GameStateModel _gameStateModel = const GameStateModel();

  GameBloc({CategoryRepository? categoryRepository})
      : _categoryRepository = categoryRepository ?? CategoryRepository(),
        super(GameInitial()) {
    // Inicializar box de forma segura
    _initializeHiveBox();
    
    // Restaurar estado si existe
    _restoreStateFromHive();
    
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<SelectCategoryEvent>(_onSelectCategory);
    on<StartCountdownEvent>(_onStartCountdown);
    on<UpdateCountdownEvent>(_onUpdateCountdown);
    on<StartTimerEvent>(_onStartTimer);
    on<UpdateTimerEvent>(_onUpdateTimer);
    on<NextWordEvent>(_onNextWord);
    on<CorrectAnswerEvent>(_onCorrectAnswer);
    on<SkipAnswerEvent>(_onSkipAnswer);
    on<TiltDeviceEvent>(_onTiltDevice);
    on<PauseGameEvent>(_onPauseGame);
    on<ResumeGameEvent>(_onResumeGame);
    on<EndGameEvent>(_onEndGame);
    on<RestartGameEvent>(_onRestartGame);
    on<CancelCountdownEvent>(_onCancelCountdown);
    on<ResetGameEvent>(_onResetGame);
  }

  /// Inicializa el box de Hive de forma segura
  void _initializeHiveBox() {
    try {
      if (Hive.isBoxOpen('app_state')) {
        _hiveBox = Hive.box('app_state');
      }
    } catch (e) {
      debugPrint('Error inicializando Hive box: $e');
      _hiveBox = null;
    }
  }

  /// Método seguro para acceder al box de Hive
  bool get _isHiveAvailable => _hiveBox != null;

  void _persistStateToHive() {
    if (!_isHiveAvailable) return;
    
    try {
      _hiveBox!.put('game_state', {
        'selectedCategoryId': _gameStateModel.selectedCategory?.id,
        'remainingWords': _gameStateModel.remainingWords,
        'currentWord': _gameStateModel.currentWord,
        'score': _gameStateModel.score,
        'timer': _gameStateModel.timer,
        'countdown': _gameStateModel.countdown,
        'status': _gameStateModel.status.index,
        'canAnswer': _gameStateModel.canAnswer,
        'tiltAngle': _gameStateModel.tiltAngle,
      });
    } catch (e) {
      debugPrint('Error persistiendo estado en Hive: $e');
    }
  }

  Future<void> _restoreStateFromHive() async {
    if (!_isHiveAvailable) return;
    
    try {
      final data = _hiveBox!.get('game_state');
      if (data != null) {
        final categoryId = data['selectedCategoryId'];
        WordCategory? selectedCategory;
        if (categoryId != null) {
          selectedCategory = await _categoryRepository.getCategoryById(categoryId);
        }
        _gameStateModel = GameStateModel(
          selectedCategory: selectedCategory,
          remainingWords: List<String>.from(data['remainingWords'] ?? []),
          currentWord: data['currentWord'] ?? '',
          score: data['score'] ?? 0,
          timer: data['timer'] ?? 90,
          countdown: data['countdown'] ?? 6,
          status: GameStatus.values[data['status'] ?? 0],
          canAnswer: data['canAnswer'] ?? true,
          tiltAngle: data['tiltAngle'] ?? 0.0,
        );
      }
    } catch (e) {
      debugPrint('Error restaurando estado desde Hive: $e');
    }
  }

  @override
  Future<void> close() {
    _isDisposed = true;
    _cleanupResources();
    return super.close();
  }

  /// Limpia todos los recursos (timers, servicios)
  void _cleanupResources() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _gameTimer?.cancel();
    _gameTimer = null;
    _motionSensorService.stop();
    _persistStateToHive();
  }

  /// Valida si una transición de estado es válida
  bool _isValidStateTransition(GameStatus from, GameStatus to) {
    switch (from) {
      case GameStatus.countdown:
        return to == GameStatus.playing || to == GameStatus.gameOver;
      case GameStatus.playing:
        return to == GameStatus.paused || to == GameStatus.gameOver;
      case GameStatus.paused:
        return to == GameStatus.playing || to == GameStatus.gameOver;
      case GameStatus.gameOver:
        return to == GameStatus.countdown;
    }
  }

  /// Actualiza el estado del modelo de forma segura
  void _updateGameState(GameStateModel Function(GameStateModel) updateFunction) {
    if (_isDisposed) return;
    
    final newState = updateFunction(_gameStateModel);
    
    // Validar transición de estado si cambió
    if (newState.status != _gameStateModel.status) {
      if (!_isValidStateTransition(_gameStateModel.status, newState.status)) {
        if (kDebugMode) {
          debugPrint('Invalid state transition: ${_gameStateModel.status} -> ${newState.status}');
        }
        return;
      }
    }
    
    _gameStateModel = newState;
    _persistStateToHive();
  }

  /// Emite un estado de forma segura
  void _safeEmit(GameState state, Emitter<GameState> emit) {
    if (_isDisposed) return;
    emit(state);
  }

  Future<void> _onLoadCategories(LoadCategoriesEvent event, Emitter<GameState> emit) async {
    _safeEmit(GameLoading(), emit);
    try {
      final categories = await _categoryRepository.loadCategories();
      if (!_isDisposed) {
        _safeEmit(CategoriesLoaded(categories), emit);
      }
    } catch (e) {
      if (!_isDisposed) {
        _safeEmit(GameError('Error al cargar categorías: $e'), emit);
      }
    }
  }

  void _onSelectCategory(SelectCategoryEvent event, Emitter<GameState> emit) {
    if (_isDisposed) return;
    
    _updateGameState((state) => state.copyWith(selectedCategory: event.category));
    _safeEmit(CategorySelected(event.category), emit);
  }

  void _onStartCountdown(StartCountdownEvent event, Emitter<GameState> emit) {
    if (_isDisposed || _gameStateModel.selectedCategory == null) return;
    
    // Limpiar recursos previos antes de iniciar
    _cleanupResources();
    
    _updateGameState((state) => state.copyWith(
      remainingWords: List.from(state.selectedCategory!.words)..shuffle(),
      status: GameStatus.countdown,
      countdown: 6,
      timer: 90,
      score: 0,
      currentWord: '',
      canAnswer: true,
      tiltAngle: 0.0,
    ));
    
    _safeEmit(GameCountdown(_gameStateModel), emit);
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    if (_isDisposed) return;
    
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || !timer.isActive) {
        timer.cancel();
        return;
      }
      
      if (_gameStateModel.status != GameStatus.countdown) {
        timer.cancel();
        return;
      }
      
      if (_gameStateModel.countdown > 1) {
        add(UpdateCountdownEvent(_gameStateModel.countdown - 1));
      } else {
        timer.cancel();
        if (_gameStateModel.status == GameStatus.countdown && !_isDisposed) {
          add(NextWordEvent());
          add(StartTimerEvent());
          _startMotionSensorService();
        }
      }
    });
  }

  void _onUpdateCountdown(UpdateCountdownEvent event, Emitter<GameState> emit) {
    if (_isDisposed || _gameStateModel.status != GameStatus.countdown) return;
    
    _updateGameState((state) => state.copyWith(countdown: event.countdown));
    _safeEmit(GameCountdown(_gameStateModel), emit);
  }

  void _onStartTimer(StartTimerEvent event, Emitter<GameState> emit) {
    if (_isDisposed) return;
    
    _updateGameState((state) => state.copyWith(status: GameStatus.playing));
    _safeEmit(GamePlaying(_gameStateModel), emit);
    _startGameTimer();
  }

  void _startGameTimer() {
    if (_isDisposed) return;
    
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || !timer.isActive) {
        timer.cancel();
        return;
      }
      
      if (_gameStateModel.status != GameStatus.playing) {
        timer.cancel();
        return;
      }
      
      if (_gameStateModel.timer > 1) {
        add(UpdateTimerEvent(_gameStateModel.timer - 1));
      } else {
        timer.cancel();
        if (_gameStateModel.status == GameStatus.playing && !_isDisposed) {
          add(EndGameEvent());
        }
      }
    });
  }

  void _onUpdateTimer(UpdateTimerEvent event, Emitter<GameState> emit) {
    if (_isDisposed || _gameStateModel.status != GameStatus.playing) return;
    
    _updateGameState((state) => state.copyWith(timer: event.timer));
    _safeEmit(GamePlaying(_gameStateModel), emit);
  }

  void _onNextWord(NextWordEvent event, Emitter<GameState> emit) {
    if (_isDisposed) return;
    
    if (_gameStateModel.remainingWords.isEmpty) {
      add(EndGameEvent());
      return;
    }

    final randomIndex = Random().nextInt(_gameStateModel.remainingWords.length);
    final newWord = _gameStateModel.remainingWords[randomIndex];
    final updatedWords = List<String>.from(_gameStateModel.remainingWords)..removeAt(randomIndex);
    
    _updateGameState((state) => state.copyWith(
      currentWord: newWord,
      remainingWords: updatedWords,
      canAnswer: true,
      tiltAngle: 0.0,
    ));

    if (_gameStateModel.status == GameStatus.playing) {
      _safeEmit(GamePlaying(_gameStateModel), emit);
    }
  }

  void _onCorrectAnswer(CorrectAnswerEvent event, Emitter<GameState> emit) {
    if (_isDisposed || _gameStateModel.status != GameStatus.playing || !_gameStateModel.canAnswer) return;
    
    _updateGameState((state) => state.copyWith(
      score: state.score + 1,
      canAnswer: false,
      tiltAngle: 90.0,
    ));
    _safeEmit(GamePlaying(_gameStateModel), emit);
    
    _scheduleNextWord();
  }

  void _onSkipAnswer(SkipAnswerEvent event, Emitter<GameState> emit) {
    if (_isDisposed || _gameStateModel.status != GameStatus.playing || !_gameStateModel.canAnswer) return;
    
    _updateGameState((state) => state.copyWith(
      canAnswer: false,
      tiltAngle: -90.0,
    ));
    _safeEmit(GamePlaying(_gameStateModel), emit);
    
    _scheduleNextWord();
  }

  void _scheduleNextWord() {
    Timer(const Duration(seconds: 1), () {
      if (!_isDisposed && _gameStateModel.status == GameStatus.playing) {
        add(NextWordEvent());
      }
    });
  }

  void _onTiltDevice(TiltDeviceEvent event, Emitter<GameState> emit) {
    if (_isDisposed || !_gameStateModel.canAnswer || _gameStateModel.status != GameStatus.playing) return;

    double tiltAngle = event.tiltAngle;
    
    // UP (inclinación positiva) = VERDE = CORRECTO
    if (tiltAngle > 2.5) {
      add(CorrectAnswerEvent());
    }
    // DOWN (inclinación negativa) = ROJO = SALTAR
    else if (tiltAngle < -2.5) {
      add(SkipAnswerEvent());
    }
    // Zona neutral
    else if (tiltAngle >= -0.5 && tiltAngle <= 0.5) {
      _updateGameState((state) => state.copyWith(
        tiltAngle: 0.0,
        canAnswer: true,
      ));
      _safeEmit(GamePlaying(_gameStateModel), emit);
    }
  }

  /// Inicia el servicio de sensores de movimiento
  void _startMotionSensorService() {
    if (_isDisposed) return;
    
    _motionSensorService.start(
      onTilt: (TiltDirection direction) {
        if (_isDisposed || _gameStateModel.status != GameStatus.playing) return;
        
        switch (direction) {
          case TiltDirection.up:
            add(CorrectAnswerEvent());
            break;
          case TiltDirection.down:
            add(SkipAnswerEvent());
            break;
          case TiltDirection.neutral:
            add(TiltDeviceEvent(0.0));
            break;
        }
      },
      onErrorCallback: (String error) {
        if (kDebugMode) {
          debugPrint('Error en sensores: $error');
        }
      },
    );
  }

  void _onPauseGame(PauseGameEvent event, Emitter<GameState> emit) {
    if (_isDisposed || _gameStateModel.status != GameStatus.playing) return;
    
    // Pausar timers y servicios
    _gameTimer?.cancel();
    _motionSensorService.stop();
    
    _updateGameState((state) => state.copyWith(status: GameStatus.paused));
    _safeEmit(GamePaused(_gameStateModel), emit);
  }

  void _onResumeGame(ResumeGameEvent event, Emitter<GameState> emit) {
    if (_isDisposed || _gameStateModel.status != GameStatus.paused) return;
    
    _updateGameState((state) => state.copyWith(status: GameStatus.playing));
    _safeEmit(GamePlaying(_gameStateModel), emit);
    
    // Reanudar timer y servicios
    _startGameTimer();
    _startMotionSensorService();
  }

  void _onEndGame(EndGameEvent event, Emitter<GameState> emit) {
    if (_isDisposed) return;
    
    _cleanupResources();
    
    _updateGameState((state) => state.copyWith(status: GameStatus.gameOver));
    _safeEmit(GameOver(_gameStateModel), emit);
  }

  void _onRestartGame(RestartGameEvent event, Emitter<GameState> emit) {
    if (_isDisposed || _gameStateModel.selectedCategory == null) return;
    
    add(StartCountdownEvent());
  }

  void _onCancelCountdown(CancelCountdownEvent event, Emitter<GameState> emit) {
    if (_isDisposed) return;
    
    _cleanupResources();
    _gameStateModel = const GameStateModel();
    add(LoadCategoriesEvent());
  }

  void _onResetGame(ResetGameEvent event, Emitter<GameState> emit) {
    if (_isDisposed) return;
    
    _cleanupResources();
    _gameStateModel = const GameStateModel();
    add(LoadCategoriesEvent());
  }
} 