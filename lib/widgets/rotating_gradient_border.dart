import 'package:flutter/material.dart';

/// A rainbow rotating border that wraps an ElevatedButton.
/// Supports both sync and async onPressed.
class RainbowButton extends StatefulWidget {
  final Future<void> Function()? onPressed; // now supports async!
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final Duration duration;
  final Color backgroundColor;

  const RainbowButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderWidth = 3,
    this.borderRadius = 12,
    this.duration = const Duration(seconds: 6),
    this.backgroundColor = Colors.black,
  });

  @override
  State<RainbowButton> createState() => _RainbowButtonState();
}

class _RainbowButtonState extends State<RainbowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (widget.onPressed == null) return;
    setState(() => _loading = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          padding: EdgeInsets.all(widget.borderWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              colors: const [
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.cyan,
                Colors.blue,
                Colors.purple,
                Colors.red,
              ],
              stops: const [0.0, 0.16, 0.33, 0.5, 0.66, 0.83, 1.0, 1.0],
              transform: GradientRotation(_controller.value * 6.283),
            ),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    widget.borderRadius - widget.borderWidth),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              elevation: 0,
            ),
            onPressed:
                widget.onPressed == null || _loading ? null : _handlePress,
            child: _loading
                ? const SizedBox(
                    height: 10,
                    width: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : widget.child,
          ),
        );
      },
    );
  }
}
