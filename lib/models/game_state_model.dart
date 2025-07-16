import 'package:equatable/equatable.dart';
import 'word_category.dart';

enum GameStatus { countdown, playing, gameOver, paused }

class GameStateModel extends Equatable {
  final WordCategory? selectedCategory;
  final List<String> remainingWords;
  final String currentWord;
  final int score;
  final int timer;
  final int countdown;
  final GameStatus status;
  final bool canAnswer;
  final double tiltAngle;

  const GameStateModel({
    this.selectedCategory,
    this.remainingWords = const [],
    this.currentWord = '',
    this.score = 0,
    this.timer = 90,
    this.countdown = 6,
    this.status = GameStatus.countdown,
    this.canAnswer = true,
    this.tiltAngle = 0.0,
  });

  GameStateModel copyWith({
    WordCategory? selectedCategory,
    List<String>? remainingWords,
    String? currentWord,
    int? score,
    int? timer,
    int? countdown,
    GameStatus? status,
    bool? canAnswer,
    double? tiltAngle,
  }) {
    return GameStateModel(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      remainingWords: remainingWords ?? this.remainingWords,
      currentWord: currentWord ?? this.currentWord,
      score: score ?? this.score,
      timer: timer ?? this.timer,
      countdown: countdown ?? this.countdown,
      status: status ?? this.status,
      canAnswer: canAnswer ?? this.canAnswer,
      tiltAngle: tiltAngle ?? this.tiltAngle,
    );
  }

  @override
  List<Object?> get props => [
        selectedCategory,
        remainingWords,
        currentWord,
        score,
        timer,
        countdown,
        status,
        canAnswer,
        tiltAngle,
      ];
} 