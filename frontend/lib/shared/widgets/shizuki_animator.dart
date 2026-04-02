import 'package:flutter/material.dart';

/// Shizuki's animation states.
/// Each state maps to a PNG sprite in assets/avatar/.
///
/// Future upgrade — Rive path:
///   Replace [ShizukiAnimator] innards with RiveAnimation.asset()
///   pointed at assets/avatar/shizuki.riv — zero API changes needed.
enum ShizukiEmotion { idle, cheer, smile, talk, sad, exciting }

extension ShizukiEmotionX on ShizukiEmotion {
  String get assetPath {
    const base = 'assets/avatar';
    switch (this) {
      case ShizukiEmotion.idle:     return '$base/shizuki_idle.png';
      case ShizukiEmotion.cheer:    return '$base/shizuki_cheer.png';
      case ShizukiEmotion.smile:    return '$base/shizuki_smile.png';
      case ShizukiEmotion.talk:     return '$base/shizuki_talk.png';
      case ShizukiEmotion.sad:      return '$base/shizuki_sad.png';
      case ShizukiEmotion.exciting: return '$base/shizuki_exciting.png';
    }
  }

  Duration get loopDuration {
    switch (this) {
      case ShizukiEmotion.idle:     return const Duration(milliseconds: 3200);
      case ShizukiEmotion.cheer:    return const Duration(milliseconds: 800);
      case ShizukiEmotion.smile:    return const Duration(milliseconds: 2000);
      case ShizukiEmotion.talk:     return const Duration(milliseconds: 500);
      case ShizukiEmotion.sad:      return const Duration(milliseconds: 3000);
      case ShizukiEmotion.exciting: return const Duration(milliseconds: 600);
    }
  }

  double get bobAmplitude {
    switch (this) {
      case ShizukiEmotion.idle:     return 18.0; // Increased significantly to simulate deep breathing
      case ShizukiEmotion.cheer:    return 26.0;
      case ShizukiEmotion.smile:    return 4.0;
      case ShizukiEmotion.talk:     return 3.0;
      case ShizukiEmotion.sad:      return 2.0;
      case ShizukiEmotion.exciting: return 24.0;
    }
  }

  double get swayAmplitude {
    switch (this) {
      case ShizukiEmotion.idle:     return 10.0; // Slight sideways shift
      case ShizukiEmotion.cheer:    return 0.0;
      case ShizukiEmotion.smile:    return 6.0;
      case ShizukiEmotion.talk:     return 3.0;
      case ShizukiEmotion.sad:      return 1.0;
      case ShizukiEmotion.exciting: return 8.0;
    }
  }

  double get scaleMin {
    switch (this) {
      case ShizukiEmotion.idle:     return 0.94; // Exaggerate breathing scale
      case ShizukiEmotion.cheer:    return 0.95;
      case ShizukiEmotion.smile:    return 0.99;
      case ShizukiEmotion.talk:     return 0.99;
      case ShizukiEmotion.sad:      return 0.97;
      case ShizukiEmotion.exciting: return 0.92;
    }
  }

  double get scaleMax {
    switch (this) {
      case ShizukiEmotion.idle:     return 1.06; // Exaggerate breathing scale
      case ShizukiEmotion.cheer:    return 1.08;
      case ShizukiEmotion.smile:    return 1.03;
      case ShizukiEmotion.talk:     return 1.01;
      case ShizukiEmotion.sad:      return 0.99;
      case ShizukiEmotion.exciting: return 1.12;
    }
  }

  String get fallbackEmoji {
    switch (this) {
      case ShizukiEmotion.idle:     return '🌸';
      case ShizukiEmotion.cheer:    return '🎉';
      case ShizukiEmotion.smile:    return '😊';
      case ShizukiEmotion.talk:     return '💬';
      case ShizukiEmotion.sad:      return '😢';
      case ShizukiEmotion.exciting: return '✨';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Displays Shizuki's character sprite with looping micro-animations
/// (bob, sway, scale-pulse) and cross-fade transitions between emotions.
class ShizukiAnimator extends StatefulWidget {
  const ShizukiAnimator({
    super.key,
    this.emotion = ShizukiEmotion.idle,
    this.size = 280.0,
    this.transitionDuration = const Duration(milliseconds: 350),
  });

  final ShizukiEmotion emotion;
  final double size;
  final Duration transitionDuration;

  @override
  State<ShizukiAnimator> createState() => _ShizukiAnimatorState();
}

class _ShizukiAnimatorState extends State<ShizukiAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _loopCtrl;
  late Animation<double> _bobAnim;
  late Animation<double> _swayAnim;
  late Animation<double> _scaleAnim;

  ShizukiEmotion _currentEmotion = ShizukiEmotion.idle;
  ShizukiEmotion _previousEmotion = ShizukiEmotion.idle;
  double _crossFade = 1.0;

  @override
  void initState() {
    super.initState();
    _currentEmotion = widget.emotion;
    _previousEmotion = widget.emotion;
    _loopCtrl = AnimationController(
      vsync: this,
      duration: widget.emotion.loopDuration,
    );
    _rebuildAnimations(widget.emotion);
    _loopCtrl.repeat(reverse: true);
  }

  void _rebuildAnimations(ShizukiEmotion emotion) {
    _loopCtrl.duration = emotion.loopDuration;
    _bobAnim = Tween<double>(begin: 0, end: emotion.bobAmplitude).animate(
        CurvedAnimation(parent: _loopCtrl, curve: Curves.easeInOut));
    _swayAnim = Tween<double>(
            begin: -emotion.swayAmplitude, end: emotion.swayAmplitude)
        .animate(CurvedAnimation(parent: _loopCtrl, curve: Curves.easeInOut));
    _scaleAnim = Tween<double>(begin: emotion.scaleMin, end: emotion.scaleMax)
        .animate(CurvedAnimation(parent: _loopCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(ShizukiAnimator old) {
    super.didUpdateWidget(old);
    if (old.emotion != widget.emotion) {
      _previousEmotion = _currentEmotion;
      _currentEmotion = widget.emotion;
      _crossFade = 0.0;
      _rebuildAnimations(_currentEmotion);
      _loopCtrl
        ..reset()
        ..repeat(reverse: true);
      _animateFade();
    }
  }

  void _animateFade() {
    const steps = 20;
    int step = 0;
    final stepDuration =
        Duration(microseconds: widget.transitionDuration.inMicroseconds ~/ steps);
    void tick() {
      step++;
      if (!mounted) return;
      setState(() => _crossFade = step / steps);
      if (step < steps) Future.delayed(stepDuration, tick);
    }
    Future.delayed(stepDuration, tick);
  }

  @override
  void dispose() {
    _loopCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size * 1.6,
      child: AnimatedBuilder(
        animation: _loopCtrl,
        builder: (context, child) => Transform.translate(
          offset: Offset(_swayAnim.value, -_bobAnim.value),
          child: Transform.scale(scale: _scaleAnim.value, child: child),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_crossFade < 1.0)
              Opacity(
                opacity: 1.0 - _crossFade,
                child: _buildSprite(_previousEmotion),
              ),
            Opacity(
              opacity: _crossFade,
              child: _buildSprite(_currentEmotion),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSprite(ShizukiEmotion emotion) {
    return Image.asset(
      emotion.assetPath,
      key: ValueKey('shizuki-${emotion.name}'),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Center(
        // FIXED: Added missing const to TextStyle
        child: Text(emotion.fallbackEmoji,
            style: const TextStyle(fontSize: 80)),
      ),
    );
  }
}