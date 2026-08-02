import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/pour_toujours_theme.dart';
import '../../core/weather/weather_models.dart';

enum AmbientSkyKind {
  clearDay,
  clearNight,
  partlyCloudyDay,
  partlyCloudyNight,
  overcast,
  rain,
  thunderstorm,
  fog,
  snow,
  sunrise,
  sunset,
}

AmbientSkyKind ambientSkyKindFor(
  CurrentWeather weather,
  DailyWeather? day,
) {
  final now = weather.time;
  if (day != null) {
    final sunriseDelta = now.difference(day.sunrise).abs();
    final sunsetDelta = now.difference(day.sunset).abs();
    if (sunriseDelta <= const Duration(minutes: 50)) {
      return AmbientSkyKind.sunrise;
    }
    if (sunsetDelta <= const Duration(minutes: 50)) {
      return AmbientSkyKind.sunset;
    }
  }
  final code = weather.weatherCode;
  if (code >= 95) return AmbientSkyKind.thunderstorm;
  if (code >= 71 && code <= 77) return AmbientSkyKind.snow;
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
    return AmbientSkyKind.rain;
  }
  if (code == 45 || code == 48) return AmbientSkyKind.fog;
  if (code >= 2 && code <= 3) {
    return weather.isDay
        ? AmbientSkyKind.partlyCloudyDay
        : AmbientSkyKind.partlyCloudyNight;
  }
  if (code == 1) {
    return weather.isDay
        ? AmbientSkyKind.partlyCloudyDay
        : AmbientSkyKind.partlyCloudyNight;
  }
  return weather.isDay ? AmbientSkyKind.clearDay : AmbientSkyKind.clearNight;
}

class AmbientSky extends StatefulWidget {
  const AmbientSky({
    super.key,
    required this.weather,
    required this.child,
    this.day,
    this.borderRadius = const BorderRadius.all(Radius.circular(30)),
    this.height,
    this.semanticLabel,
  });

  final CurrentWeather weather;
  final DailyWeather? day;
  final Widget child;
  final BorderRadius borderRadius;
  final double? height;
  final String? semanticLabel;

  @override
  State<AmbientSky> createState() => _AmbientSkyState();
}

class _AmbientSkyState extends State<AmbientSky>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _motionStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
      value: .35,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced) {
      _controller.stop();
      _controller.value = .35;
      return;
    }
    if (!_motionStarted) {
      _motionStarted = true;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = ambientSkyKindFor(widget.weather, widget.day);
    final resolvedHeight = widget.height == null
        ? null
        : math.max(widget.height!, 290).toDouble();
    return Semantics(
      container: true,
      label: widget.semanticLabel ?? _description(kind),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: SizedBox(
          height: resolvedHeight,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _AmbientSkyPainter(
                kind: kind,
                progress: _controller.value,
                theme: context.pt,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  String _description(AmbientSkyKind kind) => switch (kind) {
        AmbientSkyKind.clearDay => 'Clear daylight sky',
        AmbientSkyKind.clearNight => 'Clear night sky',
        AmbientSkyKind.partlyCloudyDay => 'Partly cloudy daylight sky',
        AmbientSkyKind.partlyCloudyNight => 'Partly cloudy night sky',
        AmbientSkyKind.overcast => 'Overcast sky',
        AmbientSkyKind.rain => 'Rainy sky',
        AmbientSkyKind.thunderstorm => 'Thunderstorm sky',
        AmbientSkyKind.fog => 'Foggy sky',
        AmbientSkyKind.snow => 'Snowy sky',
        AmbientSkyKind.sunrise => 'Sunrise sky',
        AmbientSkyKind.sunset => 'Sunset sky',
      };
}

class _AmbientSkyPainter extends CustomPainter {
  const _AmbientSkyPainter({
    required this.kind,
    required this.progress,
    required this.theme,
  });

  final AmbientSkyKind kind;
  final double progress;
  final PtThemeTokens theme;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = _gradient(kind);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
    );

    if (_isNight(kind)) _stars(canvas, size);
    if (_showsSun(kind)) _sun(canvas, size);
    if (_showsClouds(kind)) _clouds(canvas, size);
    if (kind == AmbientSkyKind.rain ||
        kind == AmbientSkyKind.thunderstorm) {
      _rain(canvas, size);
    }
    if (kind == AmbientSkyKind.fog) _fog(canvas, size);
    if (kind == AmbientSkyKind.snow) _snow(canvas, size);
    if (kind == AmbientSkyKind.thunderstorm) _lightning(canvas, size);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0x55000000)],
        ).createShader(rect),
    );
  }

  List<Color> _gradient(AmbientSkyKind value) => switch (value) {
        AmbientSkyKind.clearDay => theme.weatherDay,
        AmbientSkyKind.partlyCloudyDay => theme.weatherDay,
        AmbientSkyKind.clearNight => theme.weatherNight,
        AmbientSkyKind.partlyCloudyNight => theme.weatherNight,
        AmbientSkyKind.sunrise => const [
            Color(0xFF475D88),
            Color(0xFFE69C77),
            Color(0xFFFFD7A8),
          ],
        AmbientSkyKind.sunset => const [
            Color(0xFF362D69),
            Color(0xFFC26373),
            Color(0xFFF4B675),
          ],
        AmbientSkyKind.rain => const [Color(0xFF40566A), Color(0xFF81909A)],
        AmbientSkyKind.thunderstorm => const [
            Color(0xFF171B2D),
            Color(0xFF3C4358),
          ],
        AmbientSkyKind.fog => const [Color(0xFF8A979B), Color(0xFFD4D9D7)],
        AmbientSkyKind.snow => const [Color(0xFF8EA7BC), Color(0xFFE8F0F2)],
        AmbientSkyKind.overcast => const [
            Color(0xFF64747D),
            Color(0xFFA8B1B3),
          ],
      };

  bool _isNight(AmbientSkyKind value) =>
      value == AmbientSkyKind.clearNight ||
      value == AmbientSkyKind.partlyCloudyNight;

  bool _showsSun(AmbientSkyKind value) =>
      value == AmbientSkyKind.clearDay ||
      value == AmbientSkyKind.partlyCloudyDay ||
      value == AmbientSkyKind.sunrise ||
      value == AmbientSkyKind.sunset;

  bool _showsClouds(AmbientSkyKind value) =>
      value != AmbientSkyKind.clearDay && value != AmbientSkyKind.clearNight;

  void _stars(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .62);
    for (var i = 0; i < 25; i++) {
      final x = ((i * 47.0) % size.width) +
          math.sin(progress * math.pi * 2 + i) * 2;
      final y = (i * 29.0) % (size.height * .62);
      final radius = .7 + ((i % 4) * .28);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _sun(Canvas canvas, Size size) {
    final x = size.width *
        (.72 + math.sin(progress * math.pi * 2) * .012);
    final y = kind == AmbientSkyKind.sunrise
        ? size.height * .56
        : kind == AmbientSkyKind.sunset
            ? size.height * .48
            : size.height * .24;
    final center = Offset(x, y);
    canvas.drawCircle(
      center,
      size.shortestSide * .17,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: .55),
            const Color(0xFFFFD889).withValues(alpha: .08),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: size.shortestSide * .17),
        ),
    );
    canvas.drawCircle(
      center,
      size.shortestSide * .045,
      Paint()..color = const Color(0xFFFFE0A1).withValues(alpha: .9),
    );
  }

  void _clouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(
        alpha: kind == AmbientSkyKind.thunderstorm ? .12 : .25,
      );
    for (var i = 0; i < 4; i++) {
      final baseX =
          ((i * size.width * .31) + progress * size.width * .18) %
                  (size.width + 120) -
              60;
      final baseY = size.height * (.16 + i * .12);
      final scale = .65 + i * .08;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(baseX, baseY),
          width: 98 * scale,
          height: 28 * scale,
        ),
        cloudPaint,
      );
      canvas.drawCircle(
        Offset(baseX - 20 * scale, baseY - 8 * scale),
        19 * scale,
        cloudPaint,
      );
      canvas.drawCircle(
        Offset(baseX + 13 * scale, baseY - 13 * scale),
        24 * scale,
        cloudPaint,
      );
    }
  }

  void _rain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .25)
      ..strokeWidth = 1;
    for (var i = 0; i < 48; i++) {
      final x = ((i * 31.0) + progress * 110) % size.width;
      final y = ((i * 23.0) + progress * size.height * 1.6) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 4, y + 12), paint);
    }
  }

  void _fog(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (.22 + i * .14);
      final shift = math.sin(progress * math.pi * 2 + i) * 24;
      canvas.drawLine(
        Offset(-30 + shift, y),
        Offset(size.width + 30 + shift, y),
        paint,
      );
    }
  }

  void _snow(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .7);
    for (var i = 0; i < 34; i++) {
      final x = ((i * 41.0) + progress * 40) % size.width;
      final y = ((i * 27.0) + progress * size.height) % size.height;
      canvas.drawCircle(Offset(x, y), 1.4 + (i % 3) * .5, paint);
    }
  }

  void _lightning(Canvas canvas, Size size) {
    final visible = progress > .47 && progress < .5;
    if (!visible) return;
    final path = Path()
      ..moveTo(size.width * .72, size.height * .12)
      ..lineTo(size.width * .62, size.height * .43)
      ..lineTo(size.width * .7, size.height * .4)
      ..lineTo(size.width * .57, size.height * .72);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: .55)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientSkyPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.kind != kind;
}
