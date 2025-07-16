import 'package:equatable/equatable.dart';

class WordCategory extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<String> words;
  final String iconPath;
  final List<int> gradientColors;

  const WordCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.words,
    required this.iconPath,
    required this.gradientColors,
  });

  factory WordCategory.fromJson(Map<String, dynamic> json) {
    return WordCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      words: List<String>.from(json['words'] as List),
      iconPath: json['iconPath'] as String,
      gradientColors: List<int>.from(json['gradientColors'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'words': words,
      'iconPath': iconPath,
      'gradientColors': gradientColors,
    };
  }

  @override
  List<Object?> get props => [id, name, description, words, iconPath, gradientColors];
} 