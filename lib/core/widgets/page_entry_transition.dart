import 'package:flutter/material.dart';

/// PageEntryTransition — Reusable transition wrapper.
/// Combined approach: Guarantees frame readiness (Post-Frame Callback)
/// and a small visual delay for smoother navigation entry.
class PageEntryTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double startScale;

  const PageEntryTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
    this.startScale = 0.98,
  });

  @override
  State<PageEntryTransition> createState() => _PageEntryTransitionState();
}

class _PageEntryTransitionState extends State<PageEntryTransition> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 30), () {
        if (mounted) {
          setState(() {
            _animate = true;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _animate ? 1.0 : 0.0,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: AnimatedScale(
        scale: _animate ? 1.0 : widget.startScale,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

