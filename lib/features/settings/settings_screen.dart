import 'package:flutter/material.dart';

import '../../app/theme/pour_toujours_theme.dart';
import '../../core/settings/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.viewerName,
    required this.viewerInitials,
    required this.onSwitchProfile,
  });

  final String viewerName;
  final String viewerInitials;
  final VoidCallback onSwitchProfile;

  @override
  Widget build(BuildContext context) {
    final controller = AppSettingsScope.of(context);
    final settings = controller.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 6),
        Text(
          'Make Pour Toujours feel like yours.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.pt.secondaryText,
              ),
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'Appearance',
          child: Column(
            children: [
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: PtThemeCollection.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final collection = PtThemeCollection.values[index];
                    return _ThemePreview(
                      collection: collection,
                      selected: settings.theme == collection,
                      onTap: () => controller.update(
                        settings.copyWith(theme: collection),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (value) => controller.update(
                  settings.copyWith(themeMode: value.first),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Units and time',
          child: Column(
            children: [
              _ChoiceTile<TemperatureUnit>(
                icon: Icons.thermostat_rounded,
                title: 'Temperature',
                value: settings.temperatureUnit,
                choices: const {
                  TemperatureUnit.celsius: 'Celsius',
                  TemperatureUnit.fahrenheit: 'Fahrenheit',
                },
                onChanged: (value) => controller.update(
                  settings.copyWith(temperatureUnit: value),
                ),
              ),
              _ChoiceTile<WindUnit>(
                icon: Icons.air_rounded,
                title: 'Wind',
                value: settings.windUnit,
                choices: const {
                  WindUnit.kilometersPerHour: 'km/h',
                  WindUnit.milesPerHour: 'mph',
                },
                onChanged: (value) => controller.update(
                  settings.copyWith(windUnit: value),
                ),
              ),
              _ChoiceTile<ClockFormat>(
                icon: Icons.schedule_rounded,
                title: 'Clock',
                value: settings.clockFormat,
                choices: const {
                  ClockFormat.twelveHour: '12-hour',
                  ClockFormat.twentyFourHour: '24-hour',
                },
                onChanged: (value) => controller.update(
                  settings.copyWith(clockFormat: value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Motion and accessibility',
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: settings.reducedMotion,
            title: const Text('Reduce motion'),
            subtitle: const Text('Limits ambient and route animations.'),
            onChanged: (value) => controller.update(
              settings.copyWith(reducedMotion: value),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Profile and privacy',
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text(viewerInitials)),
                title: Text('Using Pour Toujours as $viewerName'),
                subtitle: const Text('Identity and preferences stay on this device.'),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Privacy promise'),
                subtitle: const Text(
                  'No GPS, background location, or live activity tracking. Availability is routine-based and explainable.',
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSwitchProfile,
                  icon: const Icon(Icons.switch_account_rounded),
                  label: const Text('Switch profile'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.pt.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.pt.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final T value;
  final Map<T, String> choices;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        items: [
          for (final entry in choices.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({
    required this.collection,
    required this.selected,
    required this.onTap,
  });

  final PtThemeCollection collection;
  final bool selected;
  final VoidCallback onTap;

  String get label => switch (collection) {
        PtThemeCollection.evergreen => 'Evergreen',
        PtThemeCollection.cherryCola => 'Cherry Cola',
        PtThemeCollection.midnight => 'Midnight',
        PtThemeCollection.mint => 'Mint',
        PtThemeCollection.sunset => 'Sunset',
        PtThemeCollection.paper => 'Paper',
      };

  @override
  Widget build(BuildContext context) {
    final preview = PourToujoursTheme.build(collection, Brightness.light);
    final tokens = preview.extension<PtThemeTokens>()!;
    return Semantics(
      selected: selected,
      button: true,
      label: '$label theme',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 108,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: preview.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? preview.colorScheme.primary : tokens.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: tokens.weatherDay),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: preview.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
