import 'package:equatable/equatable.dart';
import '../models/word_category.dart';
import '../models/game_state_model.dart';

abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}

class GameLoading extends GameState {}

class CategoriesLoaded extends GameState {
  final List<WordCategory> categories;

  const CategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class CategorySelected extends GameState {
  final WordCategory category;

  const CategorySelected(this.category);

  @override
  List<Object?> get props => [category];
}

class GameCountdown extends GameState {
  final GameStateModel gameState;

  const GameCountdown(this.gameState);

  @override
  List<Object?> get props => [gameState];
}

class GamePlaying extends GameState {
  final GameStateModel gameState;

  const GamePlaying(this.gameState);

  @override
  List<Object?> get props => [gameState];
}

class GamePaused extends GameState {
  final GameStateModel gameState;

  const GamePaused(this.gameState);

  @override
  List<Object?> get props => [gameState];
}

class GameOver extends GameState {
  final GameStateModel gameState;

  const GameOver(this.gameState);

  @override
  List<Object?> get props => [gameState];
}

class GameError extends GameState {
  final String message;

  const GameError(this.message);

  @override
  List<Object?> get props => [message];
} 