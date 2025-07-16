import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/game_state.dart';
import '../widgets/category_card.dart';
import '../models/word_category.dart';
import 'game_screen.dart';
import 'package:hive/hive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _rebuildCounter = 0;
  bool _isDisposed = false;
  int _selectedIndex = 0;
  
  // Estado de navegación interna para el tab "Jugar"
  String _gameNavigation = 'categories'; // 'categories', 'category_detail', 'game'
  WordCategory? _selectedCategory;
  // Preferencias de usuario
  bool _soundOn = true;
  bool _vibrationOn = true;
  bool _darkMode = false;
  final Box _settingsBox = Hive.box('settings');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Restaurar orientaciones de forma gradual para evitar problemas de desbordamiento
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        // Primero restaurar orientaciones
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        
        // Luego cargar categorías
        final gameBloc = context.read<GameBloc>();
        if (gameBloc.state is! CategoriesLoaded) {
          gameBloc.add(LoadCategoriesEvent());
        }
        // Restaurar preferencias y tab
        _restoreSettings();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_isDisposed && mounted) {
      // Incrementar contador para forzar reconstrucción
      setState(() {
        _rebuildCounter++;
      });
      
      // Recargar categorías
      final gameBloc = context.read<GameBloc>();
      if (gameBloc.state is! CategoriesLoaded) {
        gameBloc.add(LoadCategoriesEvent());
      }
      
      // Restaurar orientación después de un delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_isDisposed && mounted) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
      });
    }
  }

  void _restoreSettings() {
    setState(() {
      _selectedIndex = _settingsBox.get('selectedIndex', defaultValue: 0);
      _soundOn = _settingsBox.get('soundOn', defaultValue: true);
      _vibrationOn = _settingsBox.get('vibrationOn', defaultValue: true);
      _darkMode = _settingsBox.get('darkMode', defaultValue: false);
    });
  }

  void _persistSettings() {
    _settingsBox.put('selectedIndex', _selectedIndex);
    _settingsBox.put('soundOn', _soundOn);
    _settingsBox.put('vibrationOn', _vibrationOn);
    _settingsBox.put('darkMode', _darkMode);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Resetear navegación interna cuando cambies de tab
      if (index != 0) {
        _gameNavigation = 'categories';
        _selectedCategory = null;
      }
      _persistSettings();
    });
  }

  // Navegación interna para el tab "Jugar"
  void _navigateToCategory(WordCategory category) {
    setState(() {
      _selectedCategory = category;
      _gameNavigation = 'category_detail';
    });
  }

  void _navigateToGame() {
    // Usar Navigator.push para ir al GameScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );
  }

  // Ya no necesitamos _navigateBackFromGame porque el GameScreen usa Navigator.pop()

  void _navigateBackFromCategory() {
    if (!mounted || _isDisposed) return;
    
    try {
      setState(() {
        _gameNavigation = 'categories';
        _selectedCategory = null;
        _rebuildCounter++; // Incrementar contador para forzar reconstrucción
      });
      
      // Agregar múltiples callbacks para asegurar restauración completa
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreToCategories());
    } catch (e) {
      debugPrint('Error en _navigateBackFromCategory: $e');
      // Fallback en caso de error
      _forceResetToCategories();
    }
  }
  
  void _restoreToCategories() async {
    if (!_isDisposed && mounted) {
      try {
        // Restaurar orientaciones con delay para evitar conflictos gráficos
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        
        // Esperar un frame antes de verificar categorías
        await Future.delayed(const Duration(milliseconds: 16));
        
        if (mounted && !_isDisposed) {
          // Asegurar que las categorías estén cargadas
          final gameBloc = context.read<GameBloc>();
          if (gameBloc.state is! CategoriesLoaded) {
            gameBloc.add(LoadCategoriesEvent());
          }
          
          // Forzar un rebuild adicional si es necesario
          if (mounted) {
            setState(() {});
          }
        }
      } catch (e) {
        debugPrint('Error en _restoreToCategories: $e');
        _forceResetToCategories();
      }
    }
  }
  
  void _forceResetToCategories() {
    if (!mounted || _isDisposed) return;
    
    try {
      setState(() {
        _gameNavigation = 'categories';
        _selectedCategory = null;
        _rebuildCounter = 0; // Reset completo del contador
      });
      
      // Cargar categorías de forma forzada
      final gameBloc = context.read<GameBloc>();
      gameBloc.add(LoadCategoriesEvent());
    } catch (e) {
      debugPrint('Error en _forceResetToCategories: $e');
    }
  }

  // Función helper para obtener padding responsivo
  EdgeInsets _getResponsivePadding(Size screenSize, {bool isLandscape = false}) {
    final minDimension = isLandscape ? screenSize.height : screenSize.width;
    
    double basePadding = minDimension * 0.04;
    basePadding = basePadding.clamp(16.0, 32.0);
    
    return EdgeInsets.all(basePadding);
  }

  // Función helper para obtener tamaños de fuente responsivos
  double _getResponsiveFontSize(Size screenSize, double baseSize, {bool isLandscape = false}) {
    final minDimension = isLandscape ? screenSize.height : screenSize.width;
    
    double scaleFactor = minDimension / (isLandscape ? 400 : 600);
    scaleFactor = scaleFactor.clamp(0.8, 1.2);
    
    return (baseSize * scaleFactor).clamp(14.0, baseSize * 1.2);
  }

  @override
  Widget build(BuildContext context) {
    // Evitar reconstruir si el widget fue dispuesto
    if (_isDisposed) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Forzar reconstrucción completa con key única
    return PopScope(
      canPop: false, // Prevenir cierre automático de la app
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop || !mounted || _isDisposed) return;
        
        try {
          // Manejar navegación hacia atrás según el estado actual
          if (_selectedIndex == 0) {
            // En el tab "Jugar"
            if (_gameNavigation == 'category_detail') {
              _navigateBackFromCategory();
              return;
            }
            // Ya no manejamos 'game' aquí porque ahora usa Navigator.push/pop
          }
          
          // Si estamos en la pantalla principal de cualquier tab, salir de la app
          SystemNavigator.pop();
        } catch (e) {
          debugPrint('Error en onPopInvokedWithResult: $e');
          // Fallback seguro: forzar salida de la app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: ValueKey('home_screen_$_rebuildCounter'),
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E40AF),
                  Color(0xFF3B82F6),
                  Color(0xFF60A5FA),
                ],
              ),
            ),
            child: LayoutBuilder(
              key: ValueKey('layout_builder_$_rebuildCounter'),
              builder: (context, constraints) {
                if (_isDisposed) return const SizedBox.shrink();
                final isLandscape = constraints.maxWidth > constraints.maxHeight;
                final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
                return _buildSelectedScreen(context, isLandscape, screenSize);
              },
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(), // Siempre mostrar la barra ya que 'game' ahora usa Navigator.push
      ),
    );
  }

  Widget _buildSelectedScreen(BuildContext context, bool isLandscape, Size screenSize) {
    switch (_selectedIndex) {
      case 0:
        return _buildGameTabContent(context, isLandscape, screenSize);
      case 1:
        return _buildStatsScreen(context, isLandscape, screenSize);
      case 2:
        return _buildFavoritesScreen(context, isLandscape, screenSize);
      case 3:
        return _buildSettingsScreen(context, isLandscape, screenSize);
      default:
        return _buildGameTabContent(context, isLandscape, screenSize);
    }
  }

  Widget _buildGameTabContent(BuildContext context, bool isLandscape, Size screenSize) {
    switch (_gameNavigation) {
      case 'categories':
        return _buildCategoriesScreen(context, isLandscape, screenSize);
      case 'category_detail':
        return _buildCategoryDetailScreen(context, isLandscape, screenSize);
      // 'game' ya no se maneja aquí - ahora usa Navigator.push
      default:
        return _buildCategoriesScreen(context, isLandscape, screenSize);
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E40AF),
            Color(0xFF3B82F6),
          ],
        ),
      ),
      child: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.games_outlined),
            activeIcon: Icon(Icons.games),
            label: 'Jugar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }

  // Pantalla principal de categorías
  Widget _buildCategoriesScreen(BuildContext context, bool isLandscape, Size screenSize) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: screenSize.height * 0.7,
          maxHeight: screenSize.height,
        ),
        child: Column(
          key: ValueKey('categories_column_$_rebuildCounter'),
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, isLandscape, screenSize),
            _buildCategoriesSection(context, isLandscape, screenSize),
          ],
        ),
      ),
    );
  }

  // Pantalla de detalle de categoría integrada
  Widget _buildCategoryDetailScreen(BuildContext context, bool isLandscape, Size screenSize) {
    if (_selectedCategory == null) {
      return _buildCategoriesScreen(context, isLandscape, screenSize);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(_selectedCategory!.gradientColors[0]),
            Color(_selectedCategory!.gradientColors[1]),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildCategoryDetailAppBar(context, isLandscape, screenSize),
          Expanded(
            child: _buildCategoryDetailContent(context, isLandscape, screenSize),
          ),
        ],
      ),
    );
  }

  // _buildGameScreen eliminado - ahora el GameScreen se maneja con Navigator.push

  Widget _buildHeader(BuildContext context, bool isLandscape, Size screenSize) {
    return Container(
      key: ValueKey('header_$_rebuildCounter'),
      padding: _getResponsivePadding(screenSize, isLandscape: isLandscape),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Charadas Mahanaim',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenSize, 32, isLandscape: isLandscape),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(height: screenSize.height * 0.01),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Elige una categoría para empezar',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenSize, 16, isLandscape: isLandscape),
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context, bool isLandscape, Size screenSize) {
    return Expanded(
      key: ValueKey('categories_section_$_rebuildCounter'),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Padding(
          padding: _getResponsivePadding(screenSize, isLandscape: isLandscape),
          child: BlocBuilder<GameBloc, GameState>(
            key: ValueKey('bloc_builder_$_rebuildCounter'),
            builder: (context, state) {
              if (state is GameLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3B82F6),
                  ),
                );
              }
              
              if (state is GameError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: screenSize.width * 0.15,
                        color: Colors.red,
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      Text(
                        state.message,
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(screenSize, 16, isLandscape: isLandscape),
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      ElevatedButton(
                        onPressed: () {
                          context.read<GameBloc>().add(LoadCategoriesEvent());
                        },
                        child: Text(
                          'Reintentar',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(screenSize, 14, isLandscape: isLandscape),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              if (state is CategoriesLoaded) {
                return _buildCategoriesGrid(context, state.categories, isLandscape, screenSize);
              }
              
              // Si no hay categorías cargadas, cargarlas automáticamente
              if (state is GameInitial) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_isDisposed) {
                    context.read<GameBloc>().add(LoadCategoriesEvent());
                  }
                });
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3B82F6),
                  ),
                );
              }
              
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context, List categories, bool isLandscape, Size screenSize) {
    // Validar parámetros críticos para evitar deformaciones
    if (!mounted || _isDisposed) {
      return const SizedBox.shrink();
    }
    
    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No hay categorías disponibles',
          style: TextStyle(
            fontSize: _getResponsiveFontSize(screenSize, 16, isLandscape: isLandscape),
            color: Colors.grey[600],
          ),
        ),
      );
    }

    // Validaciones de seguridad para el tamaño de pantalla
    final safeScreenWidth = screenSize.width.isFinite && screenSize.width > 0 
        ? screenSize.width.clamp(300.0, 2000.0) 
        : 400.0;
    final safeScreenHeight = screenSize.height.isFinite && screenSize.height > 0 
        ? screenSize.height.clamp(400.0, 2000.0) 
        : 600.0;
    
    // Determinar número de columnas basado en orientación y tamaño de pantalla
    int crossAxisCount;
    double childAspectRatio;
    double spacing;
    
    try {
      if (isLandscape) {
        spacing = safeScreenWidth > 1200 ? 16 : 12;
        if (safeScreenWidth > 1200) {
          crossAxisCount = 4;
          childAspectRatio = 1.1;
        } else if (safeScreenWidth > 800) {
          crossAxisCount = 3;
          childAspectRatio = 1.0;
        } else {
          crossAxisCount = 3;
          childAspectRatio = 0.9;
        }
      } else {
        spacing = safeScreenWidth > 600 ? 18 : 16;
        if (safeScreenWidth > 600) {
          crossAxisCount = 3;
          childAspectRatio = 0.85;
        } else {
          crossAxisCount = 2;
          childAspectRatio = 0.85;
        }
      }

      // Validar que los valores calculados sean válidos y seguros
      crossAxisCount = crossAxisCount.clamp(1, 6);
      childAspectRatio = childAspectRatio.clamp(0.5, 2.0);
      spacing = spacing.clamp(8.0, 24.0);
      
    } catch (e) {
      debugPrint('Error calculating grid parameters: $e');
      // Valores fallback seguros
      crossAxisCount = isLandscape ? 3 : 2;
      childAspectRatio = 0.85;
      spacing = 16.0;
    }

    return Container(
      key: ValueKey('grid_container_$_rebuildCounter'),
      width: safeScreenWidth,
      height: safeScreenHeight * 0.8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            key: ValueKey('grid_view_${_rebuildCounter}_${constraints.maxWidth}_${constraints.maxHeight}'),
            physics: const ClampingScrollPhysics(), // Cambiar a ClampingScrollPhysics para mejor estabilidad
            shrinkWrap: true,
            cacheExtent: 200.0, // Agregar cache para mejor rendimiento
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              try {
                if (index >= categories.length || index < 0) {
                  return const SizedBox.shrink();
                }
                
                final category = categories[index];
                if (category == null) {
                  return const SizedBox.shrink();
                }
                
                return RepaintBoundary( // Agregar RepaintBoundary para optimizar renderizado
                  child: CategoryCard(
                    key: ValueKey('category_${category.id}_${_rebuildCounter}_$index'),
                    category: category,
                    isLandscape: isLandscape,
                    onTap: () {
                      if (mounted && !_isDisposed) {
                        _navigateToCategory(category);
                      }
                    },
                  ),
                );
              } catch (e) {
                debugPrint('Error building category card at index $index: $e');
                return const SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isLandscape, Size screenSize) {
    return Container(
      padding: _getResponsivePadding(screenSize, isLandscape: isLandscape),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: _getResponsiveFontSize(screenSize, 28, isLandscape: isLandscape),
          ),
          SizedBox(width: screenSize.width * 0.03),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenSize, 32, isLandscape: isLandscape),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Size screenSize, bool isLandscape) {
    return Container(
      padding: EdgeInsets.all(screenSize.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF3B82F6),
            size: _getResponsiveFontSize(screenSize, 24, isLandscape: isLandscape),
          ),
          SizedBox(width: screenSize.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(screenSize, 16, isLandscape: isLandscape),
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(screenSize, 20, isLandscape: isLandscape),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged, Size screenSize, bool isLandscape) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF3B82F6),
        size: _getResponsiveFontSize(screenSize, 24, isLandscape: isLandscape),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: _getResponsiveFontSize(screenSize, 16, isLandscape: isLandscape),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: _getResponsiveFontSize(screenSize, 14, isLandscape: isLandscape),
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF3B82F6),
      ),
    );
  }

  Widget _buildSettingButton(String title, String subtitle, IconData icon, VoidCallback onTap, Size screenSize, bool isLandscape) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF3B82F6),
        size: _getResponsiveFontSize(screenSize, 24, isLandscape: isLandscape),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: _getResponsiveFontSize(screenSize, 16, isLandscape: isLandscape),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: _getResponsiveFontSize(screenSize, 14, isLandscape: isLandscape),
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: _getResponsiveFontSize(screenSize, 16, isLandscape: isLandscape),
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildCategoryDetailAppBar(BuildContext context, bool isLandscape, Size screenSize) {
    return Padding(
      padding: EdgeInsets.all(screenSize.width * 0.03),
      child: Row(
        children: [
          GestureDetector(
            onTap: _navigateBackFromCategory,
            child: Container(
              padding: EdgeInsets.all(screenSize.width * 0.015),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
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
                color: Colors.white.withOpacity(0.2),
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

  Widget _buildCategoryDetailContent(BuildContext context, bool isLandscape, Size screenSize) {
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
          ? _buildCategoryDetailLandscapeLayout(context, screenSize)
          : _buildCategoryDetailPortraitLayout(context, screenSize),
      ),
    );
  }

  Widget _buildCategoryDetailPortraitLayout(BuildContext context, Size screenSize) {
    return Column(
      children: [
        _buildCategoryDetailInfo(false, screenSize),
        const Spacer(),
        _buildCategoryDetailPlayButton(context, false, screenSize),
        SizedBox(height: screenSize.height * 0.05),
      ],
    );
  }

  Widget _buildCategoryDetailLandscapeLayout(BuildContext context, Size screenSize) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildCategoryDetailInfo(true, screenSize),
        ),
        SizedBox(width: screenSize.width * 0.05),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCategoryDetailPlayButton(context, true, screenSize),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDetailInfo(bool isLandscape, Size screenSize) {
    if (_selectedCategory == null) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCategoryDetailIcon(isLandscape, screenSize),
        SizedBox(height: screenSize.height * 0.03),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _selectedCategory!.name,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(screenSize, 28, isLandscape: isLandscape),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
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
            _selectedCategory!.description,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(screenSize, 16, isLandscape: isLandscape),
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: screenSize.height * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz,
              color: Colors.grey[500],
              size: _getResponsiveFontSize(screenSize, 20, isLandscape: isLandscape),
            ),
            SizedBox(width: screenSize.width * 0.02),
            Text(
              '${_selectedCategory!.words.length} palabras',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenSize, 16, isLandscape: isLandscape),
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryDetailIcon(bool isLandscape, Size screenSize) {
    if (_selectedCategory == null) return const SizedBox.shrink();

    final iconSize = isLandscape 
      ? screenSize.height * 0.15 
      : screenSize.width * 0.25;
    
    // Si iconPath es una ruta de imagen
    if (_selectedCategory!.iconPath.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(screenSize.width * 0.03),
        child: Image.asset(
          _selectedCategory!.iconPath,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Color(_selectedCategory!.gradientColors[0]).withOpacity(0.2),
                borderRadius: BorderRadius.circular(screenSize.width * 0.03),
              ),
              child: Icon(
                Icons.image,
                size: iconSize * 0.5,
                color: Color(_selectedCategory!.gradientColors[0]),
              ),
            );
          },
        ),
      );
    } else {
      // Si es un emoji u otro texto
      return Text(
        _selectedCategory!.iconPath,
        style: TextStyle(fontSize: iconSize * 0.7),
      );
    }
  }

  Widget _buildCategoryDetailPlayButton(BuildContext context, bool isLandscape, Size screenSize) {
    if (_selectedCategory == null) return const SizedBox.shrink();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: screenSize.width * 0.9,
        minHeight: screenSize.height * 0.07,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(_selectedCategory!.gradientColors[0]),
              Color(_selectedCategory!.gradientColors[1]),
            ],
          ),
          borderRadius: BorderRadius.circular(screenSize.width * 0.04),
          boxShadow: [
            BoxShadow(
              color: Color(_selectedCategory!.gradientColors[0]).withOpacity(0.4),
              blurRadius: screenSize.width * 0.03,
              offset: Offset(0, screenSize.height * 0.01),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            context.read<GameBloc>().add(SelectCategoryEvent(_selectedCategory!));
            _navigateToGame();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(
              vertical: screenSize.height * 0.02,
              horizontal: screenSize.width * 0.06,
            ),
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

  Widget _buildStatsScreen(BuildContext context, bool isLandscape, Size screenSize) {
    return Column(
      children: [
        _buildSectionHeader('Estadísticas', Icons.bar_chart, isLandscape, screenSize),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Padding(
              padding: _getResponsivePadding(screenSize, isLandscape: isLandscape),
              child: Column(
                children: [
                  _buildStatCard('Juegos Jugados', '0', Icons.play_circle_outline, screenSize, isLandscape),
                  SizedBox(height: screenSize.height * 0.02),
                  _buildStatCard('Palabras Adivinadas', '0', Icons.check_circle_outline, screenSize, isLandscape),
                  SizedBox(height: screenSize.height * 0.02),
                  _buildStatCard('Tiempo Promedio', '0:00', Icons.timer_outlined, screenSize, isLandscape),
                  SizedBox(height: screenSize.height * 0.02),
                  _buildStatCard('Categoría Favorita', 'Ninguna', Icons.star_outline, screenSize, isLandscape),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesScreen(BuildContext context, bool isLandscape, Size screenSize) {
    return Column(
      children: [
        _buildSectionHeader('Favoritos', Icons.favorite, isLandscape, screenSize),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Padding(
              padding: _getResponsivePadding(screenSize, isLandscape: isLandscape),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      size: screenSize.width * 0.15,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    Text(
                      'Aún no tienes categorías favoritas',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(screenSize, 16, isLandscape: isLandscape),
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenSize.height * 0.01),
                    Text(
                      'Juega algunas partidas para descubrir tus favoritas',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(screenSize, 14, isLandscape: isLandscape),
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsScreen(BuildContext context, bool isLandscape, Size screenSize) {
    return Column(
      children: [
        _buildSectionHeader('Configuración', Icons.settings, isLandscape, screenSize),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Padding(
              padding: _getResponsivePadding(screenSize, isLandscape: isLandscape),
              child: Column(
                children: [
                  _buildSettingTile(
                    'Sonidos',
                    'Activar sonidos del juego',
                    Icons.volume_up_outlined,
                    _soundOn,
                    (value) {
                      setState(() {
                        _soundOn = value;
                        _persistSettings();
                      });
                    },
                    screenSize,
                    isLandscape,
                  ),
                  _buildSettingTile(
                    'Vibraciones',
                    'Activar vibraciones',
                    Icons.vibration,
                    _vibrationOn,
                    (value) {
                      setState(() {
                        _vibrationOn = value;
                        _persistSettings();
                      });
                    },
                    screenSize,
                    isLandscape,
                  ),
                  _buildSettingTile(
                    'Modo Oscuro',
                    'Cambiar a tema oscuro',
                    Icons.dark_mode_outlined,
                    _darkMode,
                    (value) {
                      setState(() {
                        _darkMode = value;
                        _persistSettings();
                      });
                    },
                    screenSize,
                    isLandscape,
                  ),
                  const Divider(),
                  _buildSettingButton(
                    'Acerca de',
                    'Información de la aplicación',
                    Icons.info_outline,
                    () {},
                    screenSize,
                    isLandscape,
                  ),
                  const Divider(color: Colors.red),
                  _buildEmergencyResetButton(context, screenSize, isLandscape),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyResetButton(BuildContext context, Size screenSize, bool isLandscape) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: screenSize.height * 0.01),
      child: ElevatedButton.icon(
        onPressed: () => _showEmergencyResetDialog(context),
        icon: Icon(
          Icons.refresh,
          size: _getResponsiveFontSize(screenSize, 20, isLandscape: isLandscape),
          color: Colors.red,
        ),
        label: Text(
          'Reset de Emergencia',
          style: TextStyle(
            fontSize: _getResponsiveFontSize(screenSize, 16, isLandscape: isLandscape),
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          elevation: 0,
          side: BorderSide(color: Colors.red.shade200),
          padding: EdgeInsets.symmetric(
            vertical: screenSize.height * 0.015,
            horizontal: screenSize.width * 0.04,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showEmergencyResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Reset de Emergencia'),
            ],
          ),
          content: const Text(
            'Esto reiniciará completamente la aplicación y puede resolver problemas de deformación de la interfaz.\n\n'
            '¿Estás seguro de que quieres continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performEmergencyReset();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  void _performEmergencyReset() async {
    try {
      // Mostrar indicador de carga
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Reiniciando...'),
              ],
            ),
          ),
        );
      }

      // Reset completo del estado
      setState(() {
        _gameNavigation = 'categories';
        _selectedCategory = null;
        _selectedIndex = 0;
        _rebuildCounter = 0;
      });

      // Restaurar orientaciones
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      // Esperar un momento para que se estabilice
      await Future.delayed(const Duration(milliseconds: 100));

      // Forzar recarga de categorías
      if (mounted && !_isDisposed) {
        final gameBloc = context.read<GameBloc>();
        gameBloc.add(LoadCategoriesEvent());
      }

      // Cerrar dialog de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset completado. La aplicación ha sido reiniciada.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error en reset de emergencia: $e');
      
      // Cerrar dialog de carga si está abierto
      if (mounted) {
        Navigator.of(context).pop();
        
        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error durante el reset: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

 }