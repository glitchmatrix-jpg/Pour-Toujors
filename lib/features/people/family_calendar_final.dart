import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/pour_toujours_theme.dart';
import '../../core/holidays/holiday_service.dart';
import '../../data/family_context.dart';
import '../../data/family_seed.dart';
import 'people_calendar_experience.dart';

class FamilyCalendarFinalScreen extends StatefulWidget {
  const FamilyCalendarFinalScreen({super.key, required this.viewerName});
  final String viewerName;

  @override
  State<FamilyCalendarFinalScreen> createState() =>
      _FamilyCalendarFinalScreenState();
}

class _FamilyCalendarFinalScreenState
    extends State<FamilyCalendarFinalScreen> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selected = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  String filter = 'All';
  late Future<List<FamilyEvent>> events = FamilyEventStore().load();
  late Future<List<NationalHoliday>> holidays = _loadHolidays();

  Future<List<NationalHoliday>> _loadHolidays() async {
    final groups = await Future.wait([
      for (final city in cities)
        HolidayService().fetchUpcoming(city.id, limit: 12),
    ]);
    return groups.expand((group) => group).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family calendar'),
        actions: [
          IconButton(
            tooltip: 'Add event',
            onPressed: _createEvent,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<FamilyEvent>>(
        future: events,
        builder: (context, eventSnapshot) {
          return FutureBuilder<List<NationalHoliday>>(
            future: holidays,
            builder: (context, holidaySnapshot) {
              final saved = eventSnapshot.data ?? const <FamilyEvent>[];
              final holidayValues =
                  holidaySnapshot.data ?? const <NationalHoliday>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                children: [
                  _MonthHeader(
                    month: month,
                    previous: () => setState(() {
                      month = DateTime(month.year, month.month - 1);
                    }),
                    next: () => setState(() {
                      month = DateTime(month.year, month.month + 1);
                    }),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final value in const [
                          'All',
                          'Birthdays',
                          'Holidays',
                          'Family events',
                        ]) ...[
                          ChoiceChip(
                            label: Text(value),
                            selected: filter == value,
                            onSelected: (_) => setState(() => filter = value),
                          ),
                          const SizedBox(width: 7),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _Weekdays(),
                  const SizedBox(height: 7),
                  _CalendarGrid(
                    month: month,
                    selected: selected,
                    events: saved,
                    holidays: holidayValues,
                    filter: filter,
                    onSelected: (date) => setState(() => selected = date),
                  ),
                  const SizedBox(height: 18),
                  _SelectedDay(
                    date: selected,
                    events: saved,
                    holidays: holidayValues,
                    onAdd: _createEvent,
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Upcoming',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _createEvent,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add event'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Upcoming(events: saved, holidays: holidayValues),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createEvent() async {
    final created = await Navigator.push<FamilyEvent>(
      context,
      MaterialPageRoute(builder: (_) => const EventEditorScreen()),
    );
    if (created == null) return;
    await FamilyEventStore().add(created);
    if (mounted) setState(() => events = FamilyEventStore().load());
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.previous,
    required this.next,
  });
  final DateTime month;
  final VoidCallback previous;
  final VoidCallback next;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: context.pt.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.pt.outline),
      ),
      child: Row(
        children: [
          IconButton(onPressed: previous, icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(month),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(onPressed: next, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _Weekdays extends StatelessWidget {
  const _Weekdays();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.pt.secondaryText,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.selected,
    required this.events,
    required this.holidays,
    required this.filter,
    required this.onSelected,
  });
  final DateTime month;
  final DateTime selected;
  final List<FamilyEvent> events;
  final List<NationalHoliday> holidays;
  final String filter;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final leading = DateTime(month.year, month.month).weekday - 1;
    final total = ((leading + days + 6) ~/ 7) * 7;
    final primary = Theme.of(context).colorScheme.primary;
    return GridView.builder(
      key: const ValueKey('polished-month-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: .84,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemCount: total,
      itemBuilder: (context, index) {
        final number = index - leading + 1;
        if (number < 1 || number > days) return const SizedBox.shrink();
        final date = DateTime(month.year, month.month, number);
        final items = _itemsFor(date, events, holidays, filter);
        final chosen = DateUtils.isSameDay(date, selected);
        return InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => onSelected(date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: chosen ? primary.withValues(alpha: .15) : context.pt.card,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: chosen ? primary : context.pt.outline,
                width: chosen ? 1.6 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$number', style: const TextStyle(fontWeight: FontWeight.w900)),
                const Spacer(),
                Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: [
                    for (final item in items.take(4))
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: item.color(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectedDay extends StatelessWidget {
  const _SelectedDay({
    required this.date,
    required this.events,
    required this.holidays,
    required this.onAdd,
  });
  final DateTime date;
  final List<FamilyEvent> events;
  final List<NationalHoliday> holidays;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final items = _itemsFor(date, events, holidays, 'All');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.pt.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.pt.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, d MMMM').format(date),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(onPressed: onAdd, icon: const Icon(Icons.add_rounded)),
            ],
          ),
          if (items.isEmpty)
            Text(
              'Nothing planned. A quiet day in the family calendar.',
              style: TextStyle(color: context.pt.secondaryText),
            )
          else
            for (final item in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: item.color(context).withValues(alpha: .14),
                  child: Icon(item.icon, color: item.color(context), size: 18),
                ),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
              ),
        ],
      ),
    );
  }
}

class _Upcoming extends StatelessWidget {
  const _Upcoming({required this.events, required this.holidays});
  final List<FamilyEvent> events;
  final List<NationalHoliday> holidays;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final items = <_CalendarItem>[];
    for (final birthday in familyBirthdays) {
      var date = DateTime(now.year, birthday.month, birthday.day);
      if (date.isBefore(DateTime(now.year, now.month, now.day))) {
        date = DateTime(now.year + 1, birthday.month, birthday.day);
      }
      items.add(_CalendarItem(
        date,
        birthday.name,
        'Birthday · ${DateFormat('d MMMM').format(date)}',
        _ItemType.birthday,
      ));
    }
    for (final holiday in holidays.where((item) => !item.date.isBefore(now))) {
      items.add(_CalendarItem(
        holiday.date,
        holiday.name,
        '${holiday.countryCode} holiday · ${DateFormat('d MMMM').format(holiday.date)}',
        _ItemType.holiday,
      ));
    }
    for (final event in events.where((item) => item.utcStart.isAfter(now.toUtc()))) {
      items.add(_CalendarItem(
        event.utcStart.toLocal(),
        event.title,
        DateFormat('d MMM · h:mm a').format(event.utcStart.toLocal()),
        _ItemType.event,
      ));
    }
    items.sort((a, b) => a.date.compareTo(b.date));
    return Column(
      children: [
        for (var index = 0; index < items.length && index < 12; index++) ...[
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: items[index].color(context).withValues(alpha: .14),
                child: Icon(items[index].icon, color: items[index].color(context)),
              ),
              title: Text(items[index].title),
              subtitle: Text(items[index].subtitle),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

enum _ItemType { birthday, holiday, event }

class _CalendarItem {
  const _CalendarItem(this.date, this.title, this.subtitle, this.type);
  final DateTime date;
  final String title;
  final String subtitle;
  final _ItemType type;

  IconData get icon => switch (type) {
        _ItemType.birthday => Icons.cake_outlined,
        _ItemType.holiday => Icons.flag_outlined,
        _ItemType.event => Icons.event_outlined,
      };

  Color color(BuildContext context) => switch (type) {
        _ItemType.birthday => context.pt.birthday,
        _ItemType.holiday => context.pt.holiday,
        _ItemType.event => Theme.of(context).colorScheme.primary,
      };
}

List<_CalendarItem> _itemsFor(
  DateTime date,
  List<FamilyEvent> events,
  List<NationalHoliday> holidays,
  String filter,
) {
  final values = <_CalendarItem>[];
  if (filter == 'All' || filter == 'Birthdays') {
    for (final birthday in familyBirthdays) {
      if (birthday.month == date.month && birthday.day == date.day) {
        values.add(_CalendarItem(
          date,
          '${birthday.name}’s birthday',
          'Family birthday',
          _ItemType.birthday,
        ));
      }
    }
  }
  if (filter == 'All' || filter == 'Holidays') {
    for (final holiday in holidays) {
      if (DateUtils.isSameDay(holiday.date, date)) {
        values.add(_CalendarItem(
          date,
          holiday.name,
          '${holiday.countryCode} national holiday',
          _ItemType.holiday,
        ));
      }
    }
  }
  if (filter == 'All' || filter == 'Family events') {
    for (final event in events) {
      final local = event.utcStart.toLocal();
      if (DateUtils.isSameDay(local, date)) {
        values.add(_CalendarItem(
          date,
          event.title,
          DateFormat('h:mm a').format(local),
          _ItemType.event,
        ));
      }
    }
  }
  return values;
}
