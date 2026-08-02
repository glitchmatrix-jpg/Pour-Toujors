import 'package:flutter/material.dart';

import '../../core/alerts/weather_alert_service.dart';
import '../city/city_experience.dart';

abstract final class PourToujoursRouteNames {
  static const city = '/city';
  static const dailyWeather = '/weather/day';
  static const hourlyWeather = '/weather/hourly';
  static const weatherCompare = '/weather/compare';
  static const person = '/person';
  static const overlapPlanner = '/planner';
  static const holiday = '/holiday';
  static const birthday = '/birthday';
  static const alert = '/alert';
  static const themePreview = '/theme-preview';
}

class DetailRouteArgs {
  const DetailRouteArgs({
    required this.title,
    this.subtitle,
    this.payload,
    this.viewerName,
  });

  final String title;
  final String? subtitle;
  final Object? payload;
  final String? viewerName;
}

abstract final class PourToujoursRoutes {
  static String viewerName = 'Hasan';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments is DetailRouteArgs
        ? settings.arguments! as DetailRouteArgs
        : const DetailRouteArgs(title: 'Pour Toujours');
    final page = _pageFor(settings.name, args);
    if (page == null) return null;
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 210),
      pageBuilder: (_, animation, secondaryAnimation) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .025),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Widget? _pageFor(String? name, DetailRouteArgs args) {
    if (name == PourToujoursRouteNames.city) {
      final payload = args.payload;
      final cityId = payload is CityRoutePayload
          ? payload.cityId
          : payload is String
              ? payload
              : args.title.toLowerCase();
      final selectedViewer = payload is CityRoutePayload
          ? payload.viewerName
          : args.viewerName ?? viewerName;
      return CityExperienceScreen(
        initialCityId: cityId,
        viewerName: selectedViewer,
      );
    }
    if (name == PourToujoursRouteNames.hourlyWeather ||
        name == PourToujoursRouteNames.dailyWeather) {
      if (args.payload is HourlyRoutePayload) {
        return HourlyForecastScreen(
          payload: args.payload! as HourlyRoutePayload,
        );
      }
      return _FoundationDetailPage(args: args);
    }
    if (name == PourToujoursRouteNames.weatherCompare) {
      return WeatherComparisonScreen(
        viewerName: args.viewerName ?? viewerName,
      );
    }
    if (name == PourToujoursRouteNames.alert) {
      if (args.payload is FamilyWeatherAlert) {
        return AlertDetailScreen(
          alert: args.payload! as FamilyWeatherAlert,
        );
      }
      return _FoundationDetailPage(args: args);
    }
    const placeholders = {
      PourToujoursRouteNames.person,
      PourToujoursRouteNames.overlapPlanner,
      PourToujoursRouteNames.holiday,
      PourToujoursRouteNames.birthday,
      PourToujoursRouteNames.themePreview,
    };
    return placeholders.contains(name) ? _FoundationDetailPage(args: args) : null;
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
            Icon(
              Icons.auto_awesome_rounded,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              args.title,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            if (args.subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                args.subtitle!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'This route is active and retains its typed payload for the next dedicated experience.',
            ),
          ],
        ),
      ),
    );
  }
}
