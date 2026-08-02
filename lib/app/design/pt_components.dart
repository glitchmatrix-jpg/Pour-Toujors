import 'package:flutter/material.dart';

import '../theme/pour_toujours_theme.dart';

abstract final class PtSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class PtRadii {
  static const chip = 999.0;
  static const card = 24.0;
  static const sheet = 30.0;
}

class PtPageHeader extends StatelessWidget {
  const PtPageHeader({super.key, required this.title, required this.subtitle, this.trailing});
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 6),
              Text(subtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.pt.secondaryText)),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class PtSectionHeader extends StatelessWidget {
  const PtSectionHeader(this.title, {super.key, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
          if (action != null) action!,
        ],
      );
}

class PtMetricPill extends StatelessWidget {
  const PtMetricPill({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.pt.elevated,
          borderRadius: BorderRadius.circular(PtRadii.chip),
          border: Border.all(color: context.pt.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Flexible(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          ],
        ),
      );
}

class PtAlertBanner extends StatelessWidget {
  const PtAlertBanner({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.onTap,
  });
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: context.pt.warning.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(PtRadii.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PtRadii.card),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: context.pt.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(message),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class PtEmptyState extends StatelessWidget {
  const PtEmptyState({super.key, required this.title, required this.message, this.icon = Icons.inbox_outlined});
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.pt.card,
          borderRadius: BorderRadius.circular(PtRadii.card),
          border: Border.all(color: context.pt.outline),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: context.pt.secondaryText),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: context.pt.secondaryText)),
          ],
        ),
      );
}

class PtLoadingSkeleton extends StatefulWidget {
  const PtLoadingSkeleton({super.key, this.height = 120});
  final double height;

  @override
  State<PtLoadingSkeleton> createState() => _PtLoadingSkeletonState();
}

class _PtLoadingSkeletonState extends State<PtLoadingSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: .45, end: .8).animate(_controller),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(color: context.pt.elevated, borderRadius: BorderRadius.circular(PtRadii.card)),
        ),
      );
}

class PtChartContainer extends StatelessWidget {
  const PtChartContainer({super.key, required this.child, this.height = 220});
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.pt.card,
          borderRadius: BorderRadius.circular(PtRadii.card),
          border: Border.all(color: context.pt.outline),
        ),
        child: child,
      );
}
