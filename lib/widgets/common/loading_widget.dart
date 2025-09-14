import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class LoadingWidget extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message;
  final bool showMessage;

  const LoadingWidget({
    super.key,
    this.size = 50.0,
    this.color,
    this.message,
    this.showMessage = false,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: LoadingPainter(
                  animation: _animation,
                  color: widget.color ?? AppColors.primary,
                ),
              );
            },
          ),
        ),
        if (widget.showMessage && widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class LoadingPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  LoadingPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.08;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Animated arc
    final sweepAngle = 2 * 3.14159 * 0.8 * animation.value;
    final startAngle = 2 * 3.14159 * animation.value;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SimpleLoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const SimpleLoadingWidget({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );
  }
}

class PulsingDot extends StatefulWidget {
  final double size;
  final Color? color;

  const PulsingDot({
    super.key,
    this.size = 8.0,
    this.color,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: (widget.color ?? AppColors.primary).withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class ThreeDotLoading extends StatefulWidget {
  final double dotSize;
  final Color? color;
  final double spacing;

  const ThreeDotLoading({
    super.key,
    this.dotSize = 8.0,
    this.color,
    this.spacing = 4.0,
  });

  @override
  State<ThreeDotLoading> createState() => _ThreeDotLoadingState();
}

class _ThreeDotLoadingState extends State<ThreeDotLoading>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
          (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Start animations with delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                color: (widget.color ?? AppColors.primary)
                    .withOpacity(0.3 + _animations[index].value * 0.7),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}