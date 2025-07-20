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
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                child: _CategoryImage(
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

class _CategoryImage extends StatelessWidget {
  final WordCategory category;
  final double size;

  const _CategoryImage({
    required this.category,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = _getImagePath();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF6B73FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback a icono si la imagen no se encuentra
            return Icon(
              _getFallbackIcon(),
              size: size * 0.6,
              color: const Color(0xFF6B73FF),
            );
          },
        ),
      ),
    );
  }

  String _getImagePath() {
    final name = category.name.toLowerCase();
    
    if (name.contains('personajes')) {
      return 'assets/animations/Personajesbiblicos.png';
    } else if (name.contains('historias')) {
      return 'assets/animations/Historias_biblicas.png';
    } else if (name.contains('lugares')) {
      return 'assets/animations/lugares.png';
    } else if (name.contains('objetos')) {
      return 'assets/animations/objetosbiblicos.png';
    } else if (name.contains('milagros')) {
      return 'assets/animations/milagros.png';
    } else if (name.contains('parábolas')) {
      return 'assets/animations/parabolas.png';
    } else if (name.contains('profetas')) {
      return 'assets/animations/profetas_biblicos.png';
    }
    
    // Fallback para otras categorías
    return 'assets/animations/fotocategoria.png';
  }

  IconData _getFallbackIcon() {
    final name = category.name.toLowerCase();
    
    if (name.contains('personajes')) {
      return Icons.person;
    } else if (name.contains('historias')) {
      return Icons.book;
    } else if (name.contains('lugares')) {
      return Icons.place;
    } else if (name.contains('objetos')) {
      return Icons.category;
    } else if (name.contains('milagros')) {
      return Icons.auto_awesome;
    } else if (name.contains('parábolas')) {
      return Icons.menu_book;
    } else if (name.contains('profetas')) {
      return Icons.record_voice_over;
    }
    
    return Icons.category;
  }
} 