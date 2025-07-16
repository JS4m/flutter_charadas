import 'package:flutter/material.dart';
import '../models/word_category.dart';

class CategoryCard extends StatelessWidget {
  final WordCategory category;
  final VoidCallback onTap;
  final bool isLandscape;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isLandscape ? 16 : 20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(category.gradientColors[0]),
              Color(category.gradientColors[1]),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(category.gradientColors[0]).withOpacity(0.3),
              blurRadius: isLandscape ? 8 : 10,
              offset: Offset(0, isLandscape ? 3 : 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isLandscape ? 12 : 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isLandscape ? 8 : 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isLandscape ? 8 : 12),
                ),
                child: _buildIcon(),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: isLandscape ? 12 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isLandscape ? 2 : 4),
                  Text(
                    '${category.words.length} palabras',
                    style: TextStyle(
                      fontSize: isLandscape ? 10 : 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconSize = isLandscape ? 20.0 : 32.0;
    
    // Si iconPath es una ruta de imagen
    if (category.iconPath.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(isLandscape ? 6 : 8),
        child: Image.asset(
          category.iconPath,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Si falla cargar la imagen, mostrar icono por defecto
            return Icon(
              Icons.image,
              size: iconSize,
              color: Colors.white,
            );
          },
        ),
      );
    } else {
      // Si es un emoji u otro texto
      return Text(
        category.iconPath,
        style: TextStyle(fontSize: isLandscape ? 16 : 24),
      );
    }
  }
} 