import 'package:flutter/material.dart';

abstract final class PourToujoursRouteNames {
  static const city = '/city';
  static const dailyWeather = '/weather/day';
  static const hourlyWeather = '/weather/hourly';
  static const person = '/person';
  static const overlapPlanner = '/planner';
  static const holiday = '/holiday';
  static const birthday = '/birthday';
  static const alert = '/alert';
  static const themePreview = '/theme-preview';
}

class DetailRouteArgs {
  const DetailRouteArgs({required this.title, this.subtitle, this.payload});
  final String title;
  final String? subtitle;
  final Object? payload;
}

abstract final class PourToujoursRoutes {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    const supported = {
      PourToujoursRouteNames.city,
      PourToujoursRouteNames.dailyWeather,
      PourToujoursRouteNames.hourlyWeather,
      PourToujoursRouteNames.person,
      PourToujoursRouteNames.overlapPlanner,
      PourToujoursRouteNames.holiday,
      PourToujoursRouteNames.birthday,
      PourToujoursRouteNames.alert,
      PourToujoursRouteNames.themePreview,
    };
    if (!supported.contains(settings.name)) return null;
    final args = settings.arguments is DetailRouteArgs
        ? settings.arguments! as DetailRouteArgs
        : const DetailRouteArgs(title: 'Pour Toujours');
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 210),
      pageBuilder: (_, animation, secondaryAnimation) => _FoundationDetailPage(args: args),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, .025), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _FoundationDetailPage extends StatelessWidget {
  const _FoundationDetailPage({required this.args});
  final DetailRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(args.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.auto_awesome_rounded, size: 42, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 18),
            Text(args.title, style: Theme.of(context).textTheme.displaySmall),
            if (args.subtitle != null) ...[
              const SizedBox(height: 10),
              Text(args.subtitle!, style: Theme.of(context).textTheme.bodyLarge),
            ],
            const SizedBox(height: 24),
            const Text(
              'The route and data contract are active. Its complete interactive experience is delivered in the next implementation stages.',
            ),
          ],
        ),
      ),
    );
  }
}
