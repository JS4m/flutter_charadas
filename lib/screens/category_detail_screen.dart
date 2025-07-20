import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/word_category.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
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
    // Bloquear orientación vertical en esta pantalla
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B73FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B73FF),
        title: Text(
          widget.category.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        bottom: false, // Permitir contenido hasta abajo
        child: Column(
          children: [
            Expanded(
              child: _buildContent(context),
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

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        _buildCategoryInfo(),
        _buildWordsList(),
        _buildStartButton(),
      ],
    );
  }

  Widget _buildCategoryInfo() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      child: Column(
        children: [
          _buildCategoryIcon(),
          const SizedBox(height: 16),
          Text(
            widget.category.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.category.words.length} palabras para jugar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6B73FF).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getCategoryIcon(),
        size: 60,
        color: const Color(0xFF6B73FF),
      ),
    );
  }

  IconData _getCategoryIcon() {
    final name = widget.category.name.toLowerCase();
    if (name.contains('personajes')) return Icons.person;
    if (name.contains('historias')) return Icons.book;
    if (name.contains('lugares')) return Icons.place;
    if (name.contains('objetos')) return Icons.category;
    if (name.contains('milagros')) return Icons.auto_awesome;
    if (name.contains('parábolas')) return Icons.menu_book;
    if (name.contains('profetas')) return Icons.record_voice_over;
    return Icons.category;
  }

  Widget _buildWordsList() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Palabras en esta categoría:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.category.words.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.category.words[index],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      margin: const EdgeInsets.all(20),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B73FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: const Text(
          '¡Comenzar Juego!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _startGame() {
    try {
      // Usar el GameBloc existente y seleccionar la categoría
      context.read<GameBloc>().add(SelectCategoryEvent(widget.category));
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const GameScreen(),
        ),
      );
    } catch (e) {
      // Si no hay GameBloc disponible, crear uno nuevo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => GameBloc()..add(SelectCategoryEvent(widget.category)),
            child: const GameScreen(),
          ),
        ),
      );
    }
  }
} 