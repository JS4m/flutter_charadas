import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/category_repository.dart';
import '../models/word_category.dart';
import 'category_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<WordCategory> _categories = [];
  bool _isLoading = true;
  bool _isDarkMode = false;
  late Box _settingsBox;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // Forzar orientación vertical
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _scrollController = ScrollController();
    _setupScrollListener();
    _initializeSettings();
    _loadCategories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    // NestedScrollView maneja automáticamente el comportamiento de collapse/expand
    // Solo necesitamos listener para efectos adicionales si es necesario
    _scrollController.addListener(() {
      // Performance optimized: solo actualizar estado si es necesario
      if (!mounted) return;
      
      // Lógica adicional de scroll si se necesita en el futuro
    });
  }

  void _initializeSettings() {
    try {
      if (Hive.isBoxOpen('settings')) {
        _settingsBox = Hive.box('settings');
        _isDarkMode = _settingsBox.get('darkMode', defaultValue: false);
      }
    } catch (e) {
      _isDarkMode = false;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final repository = CategoryRepository();
             final categories = await repository.loadCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onCategoryTap(WordCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(category: category),
      ),
    );
  }

  void _onSettingsTap() {
    showDialog(
      context: context,
      builder: (context) => _SettingsDialog(
        isDarkMode: _isDarkMode,
        onDarkModeChanged: _onDarkModeChanged,
      ),
    );
  }

  void _onDarkModeChanged(bool value) {
    try {
      _settingsBox.put('darkMode', value);
    } catch (e) {
      // Handle error silently
    }
    
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B73FF),
      body: SafeArea(
        bottom: false, // Permitir contenido hasta abajo
        child: Column(
          children: [
            Expanded(
              child: _buildResponsiveLayout(context),
            ),
            // Espacio para botones nativos del móvil
            Container(
              height: MediaQuery.of(context).padding.bottom + 10,
              color: const Color(0xFF6B73FF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 240.0,
          floating: true,
          pinned: true,
          snap: true,
          backgroundColor: const Color(0xFF6B73FF),
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double appBarHeight = constraints.biggest.height;
              final double statusBarHeight = MediaQuery.of(context).padding.top;
              final double maxHeight = 240.0 - kToolbarHeight - statusBarHeight;
              final double shrinkOffset = appBarHeight - kToolbarHeight - statusBarHeight;
              final double shrinkPercentage = maxHeight > 0 
                ? (1.0 - (shrinkOffset / maxHeight)).clamp(0.0, 1.0)
                : 0.0;
              
              return FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6B73FF),
                        Color(0xFF6B73FF),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header superior con badge y settings
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Opacity(
                                opacity: 1.0 - shrinkPercentage,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'Charadas Bíblicas',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _onSettingsTap,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.settings, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Título principal con efecto de fade
                          Opacity(
                            opacity: 1.0 - shrinkPercentage,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '¡Hola! 👋',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Elige una categoría\npara empezar',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Título colapsado que aparece cuando se hace scroll
                          if (shrinkPercentage > 0.5)
                            Opacity(
                              opacity: shrinkPercentage,
                              child: const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Text(
                                  'Categorías',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                title: null,
                titlePadding: EdgeInsets.zero,
                collapseMode: CollapseMode.parallax,
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: _buildContent(context),
          ),
        ),
      ],
    );
  }









  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 400,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B73FF)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Diseño responsive: 2 columnas en móvil, 3 en pantallas más grandes
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Categorías',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_categories.length} categorías disponibles',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return _buildModernCategoryCard(_categories[index], index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernCategoryCard(WordCategory category, int index) {
    // Lista de imágenes preparada para futuras implementaciones
    // final imageNames = [
    //   'img1.png', 'img2.png', 'img3.png', 'img4.png', 
    //   'img5.png', 'img6.png', 'img7.png'
    // ];
    // final imageName = imageNames[index % imageNames.length];
    
    // Colores modernos para cada categoría
    final colors = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFF2193B0), const Color(0xFF6DD5ED)],
      [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)],
      [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
      [const Color(0xFFFF7F7F), const Color(0xFFFF9A9E)],
      [const Color(0xFF667EEA), const Color(0xFF9A6AFF)],
      [const Color(0xFF36D1DC), const Color(0xFF5B86E5)],
    ];
    
    final gradientColors = colors[index % colors.length];
    
    return GestureDetector(
      onTap: () => _onCategoryTap(category),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Imagen de fondo
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    _getCategoryIcon(category.id),
                    size: 40,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              // Contenido
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getCategoryIcon(category.id),
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${category.words.length} palabras',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'personajes':
        return Icons.person;
      case 'historias':
        return Icons.auto_stories;
      case 'lugares':
        return Icons.location_on;
      case 'objetos':
        return Icons.diamond;
      case 'milagros':
        return Icons.auto_awesome;
      case 'parabolas':
        return Icons.menu_book;
      case 'profetas':
        return Icons.psychology;
      default:
        return Icons.category;
    }
  }


}

class _SettingsDialog extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const _SettingsDialog({
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: onDarkModeChanged,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}