import 'package:flutter/material.dart';
import '../models/word_category.dart';

class ResponsiveCategoryCard extends StatelessWidget {
  final WordCategory category;
  final VoidCallback onTap;
  final BoxConstraints constraints;

  const ResponsiveCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = constraints.maxWidth > constraints.maxHeight;
    final cardPadding = _getCardPadding(isLandscape);
    final iconSize = _getIconSize(isLandscape);
    final titleFontSize = _getTitleFontSize(isLandscape);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: _CategoryIcon(
                  category: category,
                  size: iconSize,
                ),
              ),
              SizedBox(height: cardPadding * 0.6),
              Expanded(
                flex: 2,
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getCardPadding(bool isLandscape) {
    if (constraints.maxWidth > 600) return 16.0; // Tablet
    return isLandscape ? 12.0 : 20.0; // Mobile
  }

  double _getIconSize(bool isLandscape) {
    if (constraints.maxWidth > 600) return 50.0; // Tablet
    return isLandscape ? 40.0 : 60.0; // Mobile
  }

  double _getTitleFontSize(bool isLandscape) {
    if (constraints.maxWidth > 600) return 14.0; // Tablet
    return isLandscape ? 12.0 : 16.0; // Mobile
  }
}

class _CategoryIcon extends StatelessWidget {
  final WordCategory category;
  final double size;

  const _CategoryIcon({
    required this.category,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData();
    final iconColor = _getIconColor();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        iconData.icon,
        size: size,
        color: iconData.color,
      ),
    );
  }

  ({IconData icon, Color color}) _getIconData() {
    switch (category.name.toLowerCase()) {
      case 'music':
        return (icon: Icons.music_note, color: Colors.orange);
      case 'movies':
        return (icon: Icons.movie, color: Colors.red);
      case 'animals':
        return (icon: Icons.pets, color: Colors.green);
      case 'food':
        return (icon: Icons.restaurant, color: Colors.orange.shade700);
      default:
        return _getBiblicalCategoryIcon();
    }
  }

  ({IconData icon, Color color}) _getBiblicalCategoryIcon() {
    final name = category.name.toLowerCase();
    
    if (name.contains('personajes')) {
      return (icon: Icons.person, color: Colors.blue);
    } else if (name.contains('historias')) {
      return (icon: Icons.book, color: Colors.teal);
    } else if (name.contains('lugares')) {
      return (icon: Icons.place, color: Colors.amber);
    } else if (name.contains('objetos')) {
      return (icon: Icons.category, color: Colors.brown);
    } else if (name.contains('milagros')) {
      return (icon: Icons.auto_awesome, color: Colors.lightGreen);
    } else if (name.contains('parábolas')) {
      return (icon: Icons.menu_book, color: Colors.deepPurple);
    } else if (name.contains('profetas')) {
      return (icon: Icons.record_voice_over, color: Colors.indigo);
    }
    
    return (icon: Icons.category, color: Colors.grey);
  }

  Color _getIconColor() => _getIconData().color;
} 