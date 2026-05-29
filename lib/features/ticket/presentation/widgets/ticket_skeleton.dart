import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Loading skeleton for ticket list/table
// Shows shimmer-like pulse animation while data is being fetched
// ─────────────────────────────────────────────────────────────────────────────

class TicketListSkeleton extends StatelessWidget {
  const TicketListSkeleton({super.key, this.itemCount = 6, this.isTableMode = false});

  final int itemCount;
  final bool isTableMode;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (_, i) => isTableMode
          ? _SkeletonTableRow(delay: i * 80)
          : _SkeletonCard(delay: i * 80),
    );
  }
}

// ── Skeleton card (mobile/tablet) ───────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.delay});
  final int delay;

  @override
  Widget build(BuildContext context) {
    return _PulseContainer(
      delay: delay,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _shimmerBox(context, width: 60, height: 20, radius: 6),
                const SizedBox(width: 10),
                Expanded(child: _shimmerBox(context, height: 16, radius: 4)),
                const SizedBox(width: 10),
                _shimmerBox(context, width: 70, height: 22, radius: 12),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _shimmerBox(context, height: 14, radius: 4)),
                const SizedBox(width: 20),
                _shimmerBox(context, width: 100, height: 12, radius: 4),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _shimmerBox(context, width: 32, height: 28, radius: 6),
                const SizedBox(width: 6),
                _shimmerBox(context, width: 32, height: 28, radius: 6),
                const SizedBox(width: 6),
                _shimmerBox(context, width: 32, height: 28, radius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton table row (desktop) ────────────────────────────────────────────
class _SkeletonTableRow extends StatelessWidget {
  const _SkeletonTableRow({required this.delay});
  final int delay;

  @override
  Widget build(BuildContext context) {
    return _PulseContainer(
      delay: delay,
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardColor,
          border: Border(bottom: BorderSide(color: context.borderColor.withOpacity(0.3))),
        ),
        child: Row(
          children: [
            _shimmerBox(context, width: 80, height: 14, radius: 4),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _shimmerBox(context, height: 14, radius: 4)),
            const SizedBox(width: 16),
            _shimmerBox(context, width: 60, height: 14, radius: 4),
            const SizedBox(width: 16),
            _shimmerBox(context, width: 70, height: 22, radius: 12),
            const SizedBox(width: 16),
            _shimmerBox(context, width: 100, height: 14, radius: 4),
            const SizedBox(width: 16),
            _shimmerBox(context, width: 80, height: 14, radius: 4),
            const SizedBox(width: 16),
            _shimmerBox(context, width: 80, height: 28, radius: 6),
          ],
        ),
      ),
    );
  }
}

// ── Pulse animation wrapper ─────────────────────────────────────────────────
class _PulseContainer extends StatefulWidget {
  const _PulseContainer({required this.child, this.delay = 0});
  final Widget child;
  final int delay;

  @override
  State<_PulseContainer> createState() => _PulseContainerState();
}

class _PulseContainerState extends State<_PulseContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(opacity: _opacity.value, child: widget.child),
    );
  }
}

// ── Shimmer box helper ──────────────────────────────────────────────────────
Widget _shimmerBox(
  BuildContext context, {
  double? width,
  required double height,
  double radius = 4,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.borderColor.withOpacity(0.3),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

// ── Ranking skeleton ────────────────────────────────────────────────────────
class RankingListSkeleton extends StatelessWidget {
  const RankingListSkeleton({super.key, this.itemCount = 5});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary row skeleton
        Row(
          children: List.generate(4, (i) => Expanded(
            child: _PulseContainer(
              delay: i * 60,
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                height: 72,
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.borderColor.withOpacity(0.3)),
                ),
              ),
            ),
          )),
        ),
        const SizedBox(height: 20),
        // Ranking items skeleton
        ...List.generate(itemCount, (i) => _PulseContainer(
          delay: (i + 4) * 80,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.borderColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                _shimmerBox(context, width: 36, height: 36, radius: 8),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(context, height: 14, radius: 4),
                      const SizedBox(height: 8),
                      _shimmerBox(context, height: 4, radius: 2),
                      const SizedBox(height: 6),
                      _shimmerBox(context, width: 160, height: 10, radius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _shimmerBox(context, width: 48, height: 48, radius: 8),
              ],
            ),
          ),
        )),
      ],
    );
  }
}
