import 'package:equatable/equatable.dart';
import '../models/word_category.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategoriesEvent extends GameEvent {}

class SelectCategoryEvent extends GameEvent {
  final WordCategory category;

  const SelectCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class StartGameEvent extends GameEvent {}

class StartCountdownEvent extends GameEvent {}

class UpdateCountdownEvent extends GameEvent {
  final int countdown;

  const UpdateCountdownEvent(this.countdown);

  @override
  List<Object?> get props => [countdown];
}

class StartTimerEvent extends GameEvent {}

class UpdateTimerEvent extends GameEvent {
  final int timer;

  const UpdateTimerEvent(this.timer);

  @override
  List<Object?> get props => [timer];
}

class NextWordEvent extends GameEvent {}

class CorrectAnswerEvent extends GameEvent {}

class SkipAnswerEvent extends GameEvent {}

class TiltDeviceEvent extends GameEvent {
  final double tiltAngle;

  const TiltDeviceEvent(this.tiltAngle);

  @override
  List<Object?> get props => [tiltAngle];
}

class EndGameEvent extends GameEvent {}

class RestartGameEvent extends GameEvent {}

class PauseGameEvent extends GameEvent {}

class ResumeGameEvent extends GameEvent {}

class CancelCountdownEvent extends GameEvent {}

class ResetGameEvent extends GameEvent {} 