import 'package:flutter/material.dart';
import 'dart:async';

// ==================== LOADING OVERLAY WIDGET ====================
class LoadingOverlay extends StatefulWidget {
  final Widget child;
  final LoadingStyle style;
  final String? message;
  final Color? overlayColor;
  final bool dismissOnTap;

  const LoadingOverlay({
    Key? key,
    required this.child,
    this.style = LoadingStyle.defaultStyle,
    this.message,
    this.overlayColor,
    this.dismissOnTap = false,
  }) : super(key: key);

  static LoadingOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<LoadingOverlayState>();
  }

  @override
  LoadingOverlayState createState() => LoadingOverlayState();
}

class LoadingOverlayState extends State<LoadingOverlay> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _minimumDelayTimer;
  DateTime? _showTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void show({int minimumDelayMs = 0}) {
    if (minimumDelayMs > 0) {
      _minimumDelayTimer?.cancel();
      _minimumDelayTimer = Timer(Duration(milliseconds: minimumDelayMs), () {
        if (mounted && !_isLoading) {
          setState(() => _isLoading = true);
          _animationController.forward();
          _showTime = DateTime.now();
        }
      });
    } else {
      if (mounted && !_isLoading) {
        setState(() => _isLoading = true);
        _animationController.forward();
        _showTime = DateTime.now();
      }
    }
  }

  void hide({int minimumVisibleMs = 0}) {
    if (minimumVisibleMs > 0 && _showTime != null) {
      final elapsed = DateTime.now().difference(_showTime!);
      final remaining = minimumVisibleMs - elapsed.inMilliseconds;
      if (remaining > 0) {
        Future.delayed(Duration(milliseconds: remaining), () {
          if (mounted) _hide();
        });
        return;
      }
    }
    _hide();
  }

  void _hide() {
    _minimumDelayTimer?.cancel();
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showTime = null;
      }
    });
  }

  @override
  void dispose() {
    _minimumDelayTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isLoading)
          FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: widget.dismissOnTap ? () => hide() : null,
              child: Container(
                color: widget.overlayColor ?? Colors.black.withOpacity(0.4),
                child: Center(
                  child: LoadingWidget(
                    style: widget.style,
                    message: widget.message,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ==================== LOADING WIDGET ====================
class LoadingWidget extends StatelessWidget {
  final LoadingStyle style;
  final String? message;
  final double? size;
  final Color? color;

  const LoadingWidget({
    Key? key,
    this.style = LoadingStyle.defaultStyle,
    this.message,
    this.size,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case LoadingStyle.material:
        return _buildMaterialLoading();
      case LoadingStyle.circular:
        return _buildCircularLoading();
      case LoadingStyle.dots:
        return _buildDotsLoading();
      case LoadingStyle.pulse:
        return _buildPulseLoading();
      case LoadingStyle.spinner:
        return _buildSpinnerLoading();
      case LoadingStyle.progress:
        return _buildProgressLoading();
      case LoadingStyle.gradient:
        return _buildGradientLoading();
      case LoadingStyle.modern:
        return _buildModernLoading();
      case LoadingStyle.minimal:
        return _buildMinimalLoading();
      default:
        return _buildDefaultLoading();
    }
  }

  // Default Style
  Widget _buildDefaultLoading() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.blue.shade600),
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Material Style
  Widget _buildMaterialLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 48,
            height: size ?? 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.blue),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Simple Circular
  Widget _buildCircularLoading() {
    return Center(
      child: SizedBox(
        width: size ?? 50,
        height: size ?? 50,
        child: CircularProgressIndicator(
          strokeWidth: 4,
          valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.blue),
        ),
      ),
    );
  }

  // Animated Dots
  Widget _buildDotsLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedDotsLoader(
            color: color ?? Colors.blue,
            size: size ?? 40,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Pulse Animation
  Widget _buildPulseLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PulseLoader(
            color: color ?? Colors.blue,
            size: size ?? 50,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Spinner Style
  Widget _buildSpinnerLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 50,
            height: size ?? 50,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.blue),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Progress Style with percentage
  Widget _buildProgressLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 60,
            height: size ?? 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.blue),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Gradient Style
  Widget _buildGradientLoading() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade400,
              Colors.purple.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.blue),
                strokeWidth: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Modern Style
  Widget _buildModernLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(color ?? const Color(0xFF6366F1)),
                strokeWidth: 3,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Minimal Style
  Widget _buildMinimalLoading() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size ?? 40,
              height: size ?? 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.white),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== ANIMATED DOTS LOADER ====================
class AnimatedDotsLoader extends StatefulWidget {
  final Color color;
  final double size;

  const AnimatedDotsLoader({
    Key? key,
    required this.color,
    required this.size,
  }) : super(key: key);

  @override
  State<AnimatedDotsLoader> createState() => _AnimatedDotsLoaderState();
}

class _AnimatedDotsLoaderState extends State<AnimatedDotsLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = _controller.value;
            final delay = index * 0.2;
            final scale = ((value + delay) % 1.0);
            return Transform.scale(
              scale: 0.3 + (scale * 0.7),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: widget.size / 3,
                height: widget.size / 3,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ==================== PULSE LOADER ====================
class PulseLoader extends StatefulWidget {
  final Color color;
  final double size;

  const PulseLoader({
    Key? key,
    required this.color,
    required this.size,
  }) : super(key: key);

  @override
  State<PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<PulseLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
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
          width: widget.size * _animation.value,
          height: widget.size * _animation.value,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: widget.size * 0.6,
              height: widget.size * 0.6,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==================== LOADING ENUM ====================
enum LoadingStyle {
  defaultStyle,
  material,
  circular,
  dots,
  pulse,
  spinner,
  progress,
  gradient,
  modern,
  minimal,
}

// ==================== LOADING HELPER CLASS ====================
class LoadingHelper {
  static LoadingOverlayState? _overlayState;
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void init(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  static void setOverlayState(LoadingOverlayState? state) {
    _overlayState = state;
  }

  static void show({
    String? message,
    LoadingStyle style = LoadingStyle.defaultStyle,
    int minimumDelayMs = 0,
  }) {
    _overlayState?.show(minimumDelayMs: minimumDelayMs);
  }

  static void hide({int minimumVisibleMs = 0}) {
    _overlayState?.hide(minimumVisibleMs: minimumVisibleMs);
  }

  static Future<T> whileAsync<T>(
      Future<T> future, {
        String? message,
        LoadingStyle style = LoadingStyle.defaultStyle,
      }) async {
    show(message: message, style: style);
    try {
      final result = await future;
      hide();
      return result;
    } catch (e) {
      hide();
      rethrow;
    }
  }
}

// ==================== DIALOG LOADER (Alternative) ====================
class DialogLoader {
  static bool _isShowing = false;

  static void show(BuildContext context, {String? message}) {
    if (_isShowing) return;
    _isShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Circular Progress Indicator
                const SizedBox(
                  width: 55,
                  height: 55,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    if (_isShowing) {
      _isShowing = false;
      Navigator.of(context).pop();
    }
  }
}