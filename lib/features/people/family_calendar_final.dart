import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/pour_toujours_theme.dart';
import '../../core/holidays/holiday_service.dart';
import '../../data/family_context.dart';
import '../../data/family_seed.dart';
import 'people_calendar_experience.dart';

class FamilyCalendarFinalScreen extends StatefulWidget {
  const FamilyCalendarFinalScreen({
    super.key,
    required this.viewerName,
  });

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
    final values = await Future.wait([
      for (final city in cities)
        HolidayService().fetchUpcoming(city.id, limit: 12),
    ]);
    final flat = values.expand((items) => items).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return flat;
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
          final saved = eventSnapshot.data ?? const <FamilyEvent>[];
          return FutureBuilder<List<NationalHoliday>>(
            future: holidays,
            builder: (context, holidaySnapshot) {
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
                  const SizedBox(height: 8),
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
                  const _WeekdayHeader(),
                  const SizedBox(height: 7),
                  _MonthGrid(
                    month: month,
                    selected: selected,
                    events: saved,
                    holidays: holidayValues,
                    filter: filter,
                    onSelected: (date) => setState(() => selected = date),
                  ),
                  const SizedBox(height: 18),
                  _SelectedDayCard(
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
                  _UpcomingList(events: saved, holidays: holidayValues),
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
    if (!mounted) return;
    setState(() => events = FamilyEventStore().load());
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      decoration: BoxDecoration(
        color: context.pt.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.pt.outline),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: previous,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
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
          IconButton(
            tooltip: 'Next month',
            onPressed: next,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

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
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
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
    return GridView.builder(
      key: const ValueKey('polished-month-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: .82,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemCount: total,
      itemBuilder: (context, index) {
        final number = index - leading + 1;
        if (number < 1 || number > days) {
          return const SizedBox.shrink();
        }
        final date = DateTime(month.year, month.month, number);
        final markers = _markers(date, events, holidays, filter);
        final isSelected = DateUtils.isSameDay(date, selected);
        final isToday = DateUtils.isSameDay(date, DateTime.now());
        return Semantics(
          button: true,
          selected: isSelected,
          label:
              '${DateFormat('EEEE, d MMMM').format(date)}, ${markers.length} family calendar items',
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => onSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.pt.accent.withValues(alpha: .16)
                    : context.pt.card,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isSelected
                      ? context.pt.accent
                      : isToday
                          ? context.pt.birthday
                          : context.pt.outline,
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isSelected ? context.pt.accent : null,
                    ),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: [
                      for (final marker in markers.take(4))
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: marker.color(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({
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
    final items = _dayItems(date, events, holidays);
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
              IconButton(
                tooltip: 'Add event on this day',
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (items.isEmpty)
            Text(
              'Nothing planned. A quiet day in the family calendar.',
              style: TextStyle(color: context.pt.secondaryText),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: item.color(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          if (item.subtitle.isNotEmpty)
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                color: context.pt.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList({required this.events, required this.holidays});

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
        date: date,
        title: birthday.name,
        subtitle: 'Birthday · ${DateFormat('d MMMM').format(date)}',
        type: _CalendarItemType.birthday,
      ));
    }
    for (final holiday in holidays.where((item) => !item.date.isBefore(now))) {
      items.add(_CalendarItem(
        date: holiday.date,
        title: holiday.name,
        subtitle: '${holiday.countryCode} holiday · ${DateFormat('d MMMM').format(holiday.date)}',
        type: _CalendarItemType.holiday,
      ));
    }
    for (final event in events.where((item) => item.utcStart.isAfter(now.toUtc()))) {
      items.add(_CalendarItem(
        date: event.utcStart.toLocal(),
        title: event.title,
        subtitle: DateFormat('d MMM · h:mm a').format(event.utcStart.toLocal()),
        type: _CalendarItemType.event,
      ));
    }
    items.sort((a, b) => a.date.compareTo(b.date));
    if (items.isEmpty) {
      return Text('No upcoming family moments.',
          style: TextStyle(color: context.pt.secondaryText));
    }
    return Column(
      children: [
        for (var index = 0; index < mathMin(items.length, 12); index++) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.pt.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.pt.outline),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: items[index].color(context).withValues(alpha: .16),
                  child: Icon(items[index].icon,
                      color: items[index].color(context), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[index].title,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(items[index].subtitle,
                          style: TextStyle(
                              color: context.pt.secondaryText, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (index != mathMin(items.length, 12) - 1)
            const SizedBox(height: 8),
        ],
      ],
    );
  }
}

enum _CalendarItemType { birthday, holiday, event }

class _CalendarItem {
  const _CalendarItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.type,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final _CalendarItemType type;

  IconData get icon => switch (type) {
        _CalendarItemType.birthday => Icons.cake_outlined,
        _CalendarItemType.holiday => Icons.flag_outlined,
        _CalendarItemType.event => Icons.event_outlined,
      };

  Color color(BuildContext context) => switch (type) {
        _CalendarItemType.birthday => context.pt.birthday,
        _CalendarItemType.holiday => context.pt.holiday,
        _CalendarItemType.event => context.pt.accent,
      };
}

List<_CalendarItem> _markers(
  DateTime date,
  List<FamilyEvent> events,
  List<NationalHoliday> holidays,
  String filter,
) {
  return _dayItems(date, events, holidays).where((item) {
    return switch (filter) {
      'Birthdays' => item.type == _CalendarItemType.birthday,
      'Holidays' => item.type == _CalendarItemType.holiday,
      'Family events' => item.type == _CalendarItemType.event,
      _ => true,
    };
  }).toList();
}

List<_CalendarItem> _dayItems(
  DateTime date,
  List<FamilyEvent> events,
  List<NationalHoliday> holidays,
) {
  final values = <_CalendarItem>[];
  for (final birthday in familyBirthdays) {
    if (birthday.month == date.month && birthday.day == date.day) {
      values.add(_CalendarItem(
        date: date,
        title: '${birthday.name}’s birthday',
        subtitle: 'Family birthday',
        type: _CalendarItemType.birthday,
      ));
    }
  }
  for (final holiday in holidays) {
    if (DateUtils.isSameDay(holiday.date, date)) {
      values.add(_CalendarItem(
        date: date,
        title: holiday.name,
        subtitle: '${holiday.countryCode} national holiday',
        type: _CalendarItemType.holiday,
      ));
    }
  }
  for (final event in events) {
    final local = event.utcStart.toLocal();
    if (DateUtils.isSameDay(local, date)) {
      values.add(_CalendarItem(
        date: date,
        title: event.title,
        subtitle: DateFormat('h:mm a').format(local),
        type: _CalendarItemType.event,
      ));
    }
  }
  return values;
}

int mathMin(int first, int second) => first < second ? first : second;
