import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/word_category.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/game_state.dart';
import 'game_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final WordCategory category;

  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Asegurar orientaciones responsive de forma gradual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    });
  }

  // Función helper para obtener tamaños responsivos
  double _getResponsiveFontSize(Size screenSize, double baseSize, {bool isLandscape = false}) {
    final minDimension = isLandscape ? screenSize.height : screenSize.width;
    double scaleFactor = minDimension / (isLandscape ? 400 : 600);
    scaleFactor = scaleFactor.clamp(0.8, 1.2);
    return (baseSize * scaleFactor).clamp(12.0, baseSize * 1.2);
  }

  // Función helper para obtener padding responsivo
  EdgeInsets _getResponsivePadding(Size screenSize, {bool isLandscape = false}) {
    final minDimension = isLandscape ? screenSize.height : screenSize.width;
    double basePadding = minDimension * 0.03;
    basePadding = basePadding.clamp(12.0, 32.0);
    return EdgeInsets.all(basePadding);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        
        // Capturar todas las referencias del contexto ANTES de cualquier operación async
        final navigator = Navigator.of(context);
        final gameBloc = context.read<GameBloc>();
        
        // Restaurar orientaciones de forma gradual
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        
        // Verificar que el widget sigue montado antes de usar las referencias capturadas
        if (mounted) {
          // Verificar estado y recargar si es necesario
          if (gameBloc.state is! CategoriesLoaded) {
            gameBloc.add(LoadCategoriesEvent());
          }
          
          // Navegar usando la referencia capturada
          navigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(widget.category.gradientColors[0]),
                  Color(widget.category.gradientColors[1]),
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape = constraints.maxWidth > constraints.maxHeight;
                final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenSize.height * 0.7,
                      maxHeight: screenSize.height,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAppBar(context, isLandscape, screenSize),
                        _buildContent(context, isLandscape, screenSize),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isLandscape, Size screenSize) {
    return Padding(
      padding: EdgeInsets.all(screenSize.width * 0.03),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(screenSize.width * 0.015),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(screenSize.width * 0.02),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: _getResponsiveFontSize(screenSize, 24, isLandscape: isLandscape),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.all(screenSize.width * 0.015),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(screenSize.width * 0.02),
              ),
              child: Icon(
                Icons.favorite_border,
                color: Colors.white,
                size: _getResponsiveFontSize(screenSize, 24, isLandscape: isLandscape),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isLandscape, Size screenSize) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: _getResponsivePadding(screenSize, isLandscape: isLandscape),
        child: isLandscape 
          ? _buildLandscapeLayout(context, screenSize)
          : _buildPortraitLayout(context, screenSize),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, Size screenSize) {
    return Column(
      children: [
        _buildCategoryInfo(false, screenSize),
        const Spacer(),
        _buildPlayButton(context, false, screenSize),
        SizedBox(height: screenSize.height * 0.05),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, Size screenSize) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildCategoryInfo(true, screenSize),
        ),
        SizedBox(width: screenSize.width * 0.05),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPlayButton(context, true, screenSize),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryInfo(bool isLandscape, Size screenSize) {
    return Column(
      mainAxisAlignment: isLandscape ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(screenSize.width * 0.04),
          decoration: BoxDecoration(
            color: Color(widget.category.gradientColors[0]).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(screenSize.width * 0.04),
          ),
          child: _buildIcon(isLandscape, screenSize),
        ),
        SizedBox(height: screenSize.height * 0.03),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.category.name,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(screenSize, 28, isLandscape: isLandscape),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: screenSize.height * 0.02),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenSize.width * 0.8,
          ),
          child: Text(
            widget.category.description,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(screenSize, 16, isLandscape: isLandscape),
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: screenSize.height * 0.025),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.04, 
            vertical: screenSize.height * 0.01
          ),
          decoration: BoxDecoration(
            color: Color(widget.category.gradientColors[0]).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(screenSize.width * 0.04),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${widget.category.words.length} palabras disponibles',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenSize, 14, isLandscape: isLandscape),
                fontWeight: FontWeight.w600,
                color: Color(widget.category.gradientColors[0]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(bool isLandscape, Size screenSize) {
    final iconSize = isLandscape 
      ? screenSize.height * 0.15 
      : screenSize.width * 0.25;
    
    // Si iconPath es una ruta de imagen
    if (widget.category.iconPath.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(screenSize.width * 0.03),
        child: Image.asset(
          widget.category.iconPath,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Si falla cargar la imagen, mostrar icono por defecto
            return Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Color(widget.category.gradientColors[0]).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(screenSize.width * 0.03),
              ),
              child: Icon(
                Icons.image,
                size: iconSize * 0.5,
                color: Color(widget.category.gradientColors[0]),
              ),
            );
          },
        ),
      );
    } else {
      // Si es un emoji u otro texto
      return Text(
        widget.category.iconPath,
        style: TextStyle(fontSize: iconSize * 0.7),
      );
    }
  }

  Widget _buildPlayButton(BuildContext context, bool isLandscape, Size screenSize) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: screenSize.width * 0.8,
        minHeight: screenSize.height * 0.07,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(widget.category.gradientColors[0]),
              Color(widget.category.gradientColors[1]),
            ],
          ),
          borderRadius: BorderRadius.circular(screenSize.width * 0.04),
          boxShadow: [
            BoxShadow(
              color: Color(widget.category.gradientColors[0]).withValues(alpha: 0.4),
              blurRadius: screenSize.width * 0.03,
              offset: Offset(0, screenSize.height * 0.01),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            context.read<GameBloc>().add(SelectCategoryEvent(widget.category));
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GameScreen(),
              ),
            ).then((_) {
              // Forzar reconstrucción de la pantalla cuando regreses del juego
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // CRÍTICO: Verificar que el widget sigue montado
                if (!mounted) return;
                
                // Restaurar orientaciones gradualmente
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]);
                
                // Recargar categorías
                final gameBloc = context.read<GameBloc>();
                if (gameBloc.state is! CategoriesLoaded) {
                  gameBloc.add(LoadCategoriesEvent());
                }
              });
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenSize.width * 0.04),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: _getResponsiveFontSize(screenSize, 28, isLandscape: isLandscape),
                ),
                SizedBox(width: screenSize.width * 0.02),
                Text(
                  'JUGAR!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(screenSize, 18, isLandscape: isLandscape),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 