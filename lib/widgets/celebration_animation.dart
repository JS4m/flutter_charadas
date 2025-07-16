import 'dart:math';
import 'package:flutter/material.dart';

class CelebrationAnimation extends StatefulWidget {
  const CelebrationAnimation({super.key});

  @override
  State<CelebrationAnimation> createState() => _CelebrationAnimationState();
}

class _CelebrationAnimationState extends State<CelebrationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _sparkleController;
  late List<ConfettiParticle> confettiParticles;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Crear partículas de confeti
    confettiParticles = List.generate(50, (index) => ConfettiParticle(
      color: _getRandomColor(),
      size: random.nextDouble() * 8 + 4,
      startX: random.nextDouble(),
      startY: -0.1,
      velocityX: (random.nextDouble() - 0.5) * 2,
      velocityY: random.nextDouble() * 2 + 1,
      rotation: random.nextDouble() * 2 * pi,
      rotationSpeed: (random.nextDouble() - 0.5) * 10,
    ));

    // Iniciar animaciones
    _confettiController.forward();
    _sparkleController.repeat();
  }

  @override
  void dispose() {
    // Detener las animaciones antes de hacer dispose
    _confettiController.stop();
    _sparkleController.stop();
    
    // Hacer dispose de los controllers
    _confettiController.dispose();
    _sparkleController.dispose();
    
    super.dispose();
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    // Verificar que el widget esté montado antes de construir
    if (!mounted) {
      return const SizedBox.shrink();
    }
    
    return Stack(
      children: [
        // Confeti
        AnimatedBuilder(
          animation: _confettiController,
          builder: (context, child) {
            if (!mounted) return const SizedBox.shrink();
            return CustomPaint(
              painter: ConfettiPainter(
                particles: confettiParticles,
                progress: _confettiController.value,
              ),
              size: Size.infinite,
            );
          },
        ),
        // Destellos
        AnimatedBuilder(
          animation: _sparkleController,
          builder: (context, child) {
            if (!mounted) return const SizedBox.shrink();
            return CustomPaint(
              painter: SparklePainter(
                progress: _sparkleController.value,
                random: random,
              ),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }
}

class ConfettiParticle {
  final Color color;
  final double size;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.color,
    required this.size,
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1.0 - progress * 0.5)
        ..style = PaintingStyle.fill;

      final x = (particle.startX + particle.velocityX * progress) * size.width;
      final y = (particle.startY + particle.velocityY * progress) * size.height;
      final currentRotation = particle.rotation + particle.rotationSpeed * progress;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(currentRotation);

      // Dibujar diferentes formas de confeti
      if (particle.size > 6) {
        // Rectángulo
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          paint,
        );
      } else {
        // Círculo
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SparklePainter extends CustomPainter {
  final double progress;
  final Random random;

  SparklePainter({
    required this.progress,
    required this.random,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Crear destellos aleatorios
    for (int i = 0; i < 20; i++) {
      final opacity = (sin(progress * 2 * pi + i) + 1) / 2;
      paint.color = Colors.white.withOpacity(opacity * 0.8);

      final x = (random.nextDouble() * size.width);
      final y = (random.nextDouble() * size.height);
      final sparkleSize = random.nextDouble() * 4 + 2;

      // Dibujar estrella de 4 puntas
      canvas.save();
      canvas.translate(x, y);
      
      // Línea horizontal
      canvas.drawLine(
        Offset(-sparkleSize, 0),
        Offset(sparkleSize, 0),
        paint..strokeWidth = 2,
      );
      
      // Línea vertical
      canvas.drawLine(
        Offset(0, -sparkleSize),
        Offset(0, sparkleSize),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 