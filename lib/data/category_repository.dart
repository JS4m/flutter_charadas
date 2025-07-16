import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/word_category.dart';

class CategoryRepository {
  static const String _categoriesPath = 'assets/data/categories.json';

  Future<List<WordCategory>> loadCategories() async {
    try {
      final String jsonString = await rootBundle.loadString(_categoriesPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> categoriesJson = jsonData['categories'];
      
      return categoriesJson
          .map((json) => WordCategory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error loading categories: $e');
    }
  }

  Future<WordCategory?> getCategoryById(String id) async {
    final categories = await loadCategories();
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
} 