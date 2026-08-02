import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/theme/pour_toujours_theme.dart';
import '../../core/time/availability_engine.dart';
import '../../core/weather/weather_service.dart';
import '../../data/family_context.dart';
import '../../data/family_graph.dart';
import '../../data/family_seed.dart';

class PersonRoutePayload {
  const PersonRoutePayload({required this.personName, required this.viewerName});
  final String personName;
  final String viewerName;
}

class BirthdayRoutePayload {
  const BirthdayRoutePayload({required this.personName, required this.viewerName});
  final String personName;
  final String viewerName;
}

enum FamilyEventType {
  familyCall,
  birthdayPlan,
  visit,
  flight,
  exam,
  appointment,
  dinner,
  celebration,
  custom,
}

class FamilyEvent {
  const FamilyEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.utcStart,
    required this.timezone,
    required this.participants,
    this.notes = '',
  });

  final String id;
  final String title;
  final FamilyEventType type;
  final DateTime utcStart;
  final String timezone;
  final List<String> participants;
  final String notes;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'utcStart': utcStart.toUtc().toIso8601String(),
        'timezone': timezone,
        'participants': participants,
        'notes': notes,
      };

  factory FamilyEvent.fromJson(Map<String, dynamic> json) => FamilyEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        type: FamilyEventType.values.firstWhere(
          (value) => value.name == json['type'],
          orElse: () => FamilyEventType.custom,
        ),
        utcStart: DateTime.parse(json['utcStart'] as String).toUtc(),
        timezone: json['timezone'] as String,
        participants: List<String>.from(json['participants'] as List? ?? const []),
        notes: json['notes'] as String? ?? '',
      );
}

class FamilyEventStore {
  static const _key = 'pour_toujours_family_events_v1';

  Future<List<FamilyEvent>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => FamilyEvent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<FamilyEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(events.map((event) => event.toJson()).toList()));
  }

  Future<void> add(FamilyEvent event) async {
    final events = await load();
    await save([...events, event]);
  }
}

class PersonDetailScreen extends StatelessWidget {
  const PersonDetailScreen({super.key, required this.payload});
  final PersonRoutePayload payload;

  @override
  Widget build(BuildContext context) {
    final person = _member(payload.personName);
    final viewer = _member(payload.viewerName);
    final city = _city(person.cityId);
    final local = tz.TZDateTime.now(tz.getLocation(city.timezone));
    final viewerCity = _city(viewer.cityId);
    final viewerLocal = tz.TZDateTime.now(tz.getLocation(viewerCity.timezone));
    final availability = evaluateAvailability(member: person, city: city);
    final birthday = _birthday(person.name);
    final nextFree = _nextFree(person, city);
    final relation = familyGraph.relationship(viewer: viewer.name, person: person.name);

    return Scaffold(
      appBar: AppBar(title: Text(person.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 50),
        children: [
          Center(
            child: CircleAvatar(
              radius: 52,
              backgroundColor: context.pt.accent.withValues(alpha: .14),
              child: Text(
                person.initials,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(person.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          Text(relation, textAlign: TextAlign.center, style: TextStyle(color: context.pt.secondaryText)),
          const SizedBox(height: 22),
          _InfoCard(
            title: '${city.name}, ${city.country}',
            icon: Icons.public_rounded,
            children: [
              _line('Local time', DateFormat('EEEE, d MMM · h:mm a').format(local)),
              _line('Difference from you', _offsetText(local.timeZoneOffset - viewerLocal.timeZoneOffset)),
              _line('Daylight', local.hour >= 6 && local.hour < 18 ? 'Likely daylight' : 'Likely night'),
              _line('Next clock change', _nextClockChange(city.timezone)),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder(
            future: WeatherService().fetchBundle(city.id),
            builder: (context, snapshot) {
              final bundle = snapshot.data;
              return _InfoCard(
                title: 'Right now',
                icon: Icons.wb_cloudy_outlined,
                children: [
                  _line('Availability', availability.label),
                  _line('Confidence', availability.confidence.name),
                  _line('Why', availability.reason),
                  _line('Next likely free', DateFormat('EEE h:mm a').format(nextFree)),
                  if (bundle != null) _line('Weather', '${bundle.condition} · ${bundle.current.temperature.round()}°C'),
                  _line('Recommendation', _contactRecommendation(person, availability, nextFree)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Birthday and local context',
            icon: Icons.cake_outlined,
            children: [
              _line('Birthday', birthday == null ? 'Unknown' : DateFormat('d MMMM').format(birthday)),
              if (birthday != null) _line('Countdown', '${_daysUntil(birthday)} days'),
              _line('Holiday context', _holidayContext(city.country, local)),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Routine',
            icon: Icons.schedule_rounded,
            children: [
              Text(person.routine.summary),
              const SizedBox(height: 8),
              Text('This routine drives the availability estimate above. It is never treated as live activity.', style: TextStyle(color: context.pt.secondaryText, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoutineEditorScreen(person: person))),
            icon: const Icon(Icons.edit_calendar_outlined),
            label: const Text('Edit routine'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _recordThinkingOfYou(context, person.name),
            icon: const Icon(Icons.favorite_border_rounded),
            label: const Text('Thinking of you'),
          ),
        ],
      ),
    );
  }
}

class RoutineEditorScreen extends StatefulWidget {
  const RoutineEditorScreen({super.key, required this.person});
  final FamilyMember person;

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  late List<TimeBand> bands = [...widget.person.routine.bands];

  @override
  Widget build(BuildContext context) {
    final city = _city(widget.person.cityId);
    return Scaffold(
      appBar: AppBar(title: Text('${widget.person.name} · routine')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBlock,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add block'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Text('Times are edited in ${city.name} local time (${city.timezone}).', style: TextStyle(color: context.pt.secondaryText)),
          const SizedBox(height: 12),
          for (var index = 0; index < bands.length; index++)
            Card(
              child: ListTile(
                leading: Icon(_routineIcon(bands[index].kind)),
                title: Text('${_minutes(bands[index].startMinute)}–${_minutes(bands[index].endMinute)} · ${bands[index].kind.name}'),
                subtitle: Text('${_weekdayText(bands[index].weekdays)}\n${bands[index].reason}'),
                isThreeLine: true,
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => bands.removeAt(index))),
              ),
            ),
          const SizedBox(height: 12),
          Text('Preview: ${_previewExplanation()}', style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _addBlock() async {
    var kind = AvailabilityKind.likelyFree;
    var start = const TimeOfDay(hour: 18, minute: 0);
    var end = const TimeOfDay(hour: 21, minute: 0);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Add routine block'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField(
                initialValue: kind,
                items: AvailabilityKind.values.map((value) => DropdownMenuItem(value: value, child: Text(value.name))).toList(),
                onChanged: (value) => update(() => kind = value ?? kind),
              ),
              ListTile(title: const Text('Starts'), trailing: Text(start.format(context)), onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: start);
                if (picked != null) update(() => start = picked);
              }),
              ListTile(title: const Text('Ends'), trailing: Text(end.format(context)), onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: end);
                if (picked != null) update(() => end = picked);
              }),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    if (result == true) {
      setState(() => bands.add(TimeBand(
            startMinute: start.hour * 60 + start.minute,
            endMinute: end.hour * 60 + end.minute,
            kind: kind,
            reason: 'User-edited recurring routine block.',
            confidence: ConfidenceLevel.medium,
          )));
    }
  }

  String _previewExplanation() {
    final now = tz.TZDateTime.now(tz.getLocation(_city(widget.person.cityId).timezone));
    final minute = now.hour * 60 + now.minute;
    final matching = bands.where((band) => band.applies(now.weekday, minute)).firstOrNull;
    return matching == null ? 'No block applies now, so availability is unknown.' : '${matching.kind.name} because ${matching.reason.toLowerCase()}';
  }
}

class ContactPlannerScreen extends StatefulWidget {
  const ContactPlannerScreen({super.key, required this.viewerName});
  final String viewerName;

  @override
  State<ContactPlannerScreen> createState() => _ContactPlannerScreenState();
}

class _ContactPlannerScreenState extends State<ContactPlannerScreen> {
  final selected = <String>{'Hasan', 'Ramsha', 'Salman'};
  DateTime date = DateTime.now();
  int earliest = 7;
  int latest = 23;

  @override
  Widget build(BuildContext context) {
    final options = _scoreWindows(selected, date, earliest, latest);
    return Scaffold(
      appBar: AppBar(title: const Text('Family contact planner')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 50),
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: familyMembers.map((member) => FilterChip(
              label: Text(member.name),
              selected: selected.contains(member.name),
              onSelected: (value) => setState(() => value ? selected.add(member.name) : selected.remove(member.name)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Date'),
            subtitle: Text(DateFormat('EEEE, d MMMM').format(date)),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: () async {
              final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: date);
              if (picked != null) setState(() => date = picked);
            },
          ),
          Text('Acceptable local boundary: $earliest:00–$latest:00'),
          RangeSlider(values: RangeValues(earliest.toDouble(), latest.toDouble()), min: 0, max: 24, divisions: 24, onChanged: (value) => setState(() { earliest = value.start.round(); latest = value.end.round(); })),
          const SizedBox(height: 12),
          for (final option in options.take(8)) Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(option.rating.substring(0, 1))),
              title: Text('${DateFormat('EEE h:mm a').format(option.utc.toLocal())} · ${option.rating}'),
              subtitle: Text(option.explanation),
              trailing: option.rating == 'Comfortable' ? const Icon(Icons.star_rounded) : null,
              onTap: () => _saveCall(context, option.utc),
            ),
          ),
        ],
      ),
    );
  }
}

class FamilyCalendarScreen extends StatefulWidget {
  const FamilyCalendarScreen({super.key, required this.viewerName});
  final String viewerName;

  @override
  State<FamilyCalendarScreen> createState() => _FamilyCalendarScreenState();
}

class _FamilyCalendarScreenState extends State<FamilyCalendarScreen> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  String filter = 'All';
  late Future<List<FamilyEvent>> events = FamilyEventStore().load();

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final leading = DateTime(month.year, month.month, 1).weekday - 1;
    return Scaffold(
      appBar: AppBar(title: const Text('Family calendar')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _createEvent, icon: const Icon(Icons.add), label: const Text('Event')),
      body: FutureBuilder<List<FamilyEvent>>(
        future: events,
        builder: (context, snapshot) {
          final saved = snapshot.data ?? const <FamilyEvent>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 100),
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)),
                  Expanded(child: Text(DateFormat('MMMM yyyy').format(month), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)),
                  IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right)),
                ],
              ),
              Wrap(spacing: 6, children: ['All', 'Birthdays', 'Holidays', 'Family events'].map((value) => ChoiceChip(label: Text(value), selected: filter == value, onSelected: (_) => setState(() => filter = value))).toList()),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: .72, crossAxisSpacing: 3, mainAxisSpacing: 3),
                itemCount: leading + days,
                itemBuilder: (context, index) {
                  if (index < leading) return const SizedBox.shrink();
                  final day = index - leading + 1;
                  final date = DateTime(month.year, month.month, day);
                  final labels = _calendarLabels(date, saved, filter);
                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: context.pt.card, borderRadius: BorderRadius.circular(9), border: Border.all(color: context.pt.outline)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$day', style: const TextStyle(fontWeight: FontWeight.w800)),
                      for (final label in labels.take(3)) Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8)),
                    ]),
                  );
                },
              ),
              const SizedBox(height: 22),
              Text('Upcoming', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final item in _agenda(saved)) ListTile(leading: Icon(item.icon), title: Text(item.title), subtitle: Text(item.subtitle)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createEvent() async {
    final created = await Navigator.push<FamilyEvent>(context, MaterialPageRoute(builder: (_) => const EventEditorScreen()));
    if (created != null) {
      await FamilyEventStore().add(created);
      setState(() => events = FamilyEventStore().load());
    }
  }
}

class EventEditorScreen extends StatefulWidget {
  const EventEditorScreen({super.key});
  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  final title = TextEditingController();
  FamilyEventType type = FamilyEventType.familyCall;
  DateTime date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay time = const TimeOfDay(hour: 19, minute: 0);
  String timezone = 'Asia/Karachi';
  final participants = <String>{'Hasan'};

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create family event')),
        body: ListView(padding: const EdgeInsets.all(18), children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          DropdownButtonFormField(initialValue: type, decoration: const InputDecoration(labelText: 'Type'), items: FamilyEventType.values.map((value) => DropdownMenuItem(value: value, child: Text(value.name))).toList(), onChanged: (value) => setState(() => type = value ?? type)),
          DropdownButtonFormField(initialValue: timezone, decoration: const InputDecoration(labelText: 'Event timezone'), items: cities.map((city) => DropdownMenuItem(value: city.timezone, child: Text('${city.name} · ${city.timezone}'))).toList(), onChanged: (value) => setState(() => timezone = value ?? timezone)),
          ListTile(title: const Text('Date'), subtitle: Text(DateFormat('d MMMM yyyy').format(date)), onTap: () async { final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)), initialDate: date); if (picked != null) setState(() => date = picked); }),
          ListTile(title: const Text('Time'), subtitle: Text(time.format(context)), onTap: () async { final picked = await showTimePicker(context: context, initialTime: time); if (picked != null) setState(() => time = picked); }),
          Wrap(spacing: 6, children: familyMembers.map((member) => FilterChip(label: Text(member.name), selected: participants.contains(member.name), onSelected: (value) => setState(() => value ? participants.add(member.name) : participants.remove(member.name)))).toList()),
          const SizedBox(height: 16),
          Text(_eventWarning(), style: TextStyle(color: context.pt.warning, fontSize: 11)),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Save event')),
        ]),
      );

  void _save() {
    final location = tz.getLocation(timezone);
    final local = tz.TZDateTime(location, date.year, date.month, date.day, time.hour, time.minute);
    Navigator.pop(context, FamilyEvent(id: DateTime.now().microsecondsSinceEpoch.toString(), title: title.text.trim().isEmpty ? type.name : title.text.trim(), type: type, utcStart: local.toUtc(), timezone: timezone, participants: participants.toList()));
  }

  String _eventWarning() {
    final location = tz.getLocation(timezone);
    final local = tz.TZDateTime(location, date.year, date.month, date.day, time.hour, time.minute);
    final reconstructed = tz.TZDateTime.from(local.toUtc(), location);
    if (reconstructed.hour != time.hour || reconstructed.minute != time.minute) return 'This local time may be skipped or shifted by a clock change.';
    if (time.hour < 7 || time.hour >= 23) return 'This time may overlap likely sleep for some participants.';
    return 'Times will be stored as UTC and displayed in each participant’s local timezone.';
  }
}

class BirthdayDetailScreen extends StatelessWidget {
  const BirthdayDetailScreen({super.key, required this.payload});
  final BirthdayRoutePayload payload;

  @override
  Widget build(BuildContext context) {
    final person = _member(payload.personName);
    final viewer = _member(payload.viewerName);
    final birthday = _birthday(person.name);
    if (birthday == null) return Scaffold(appBar: AppBar(title: Text(person.name)), body: const Center(child: Text('Birthday unknown')));
    final city = _city(person.cityId);
    final viewerCity = _city(viewer.cityId);
    final next = _nextBirthday(birthday);
    final midnight = tz.TZDateTime(tz.getLocation(city.timezone), next.year, next.month, next.day);
    final viewerEquivalent = tz.TZDateTime.from(midnight.toUtc(), tz.getLocation(viewerCity.timezone));
    return Scaffold(
      appBar: AppBar(title: Text('${person.name} · birthday')),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        const Icon(Icons.cake_rounded, size: 64),
        Text('${_daysUntil(birthday)} days', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 14),
        _line('Birthday', DateFormat('d MMMM').format(birthday)),
        _line('Local midnight', '${DateFormat('d MMM h:mm a').format(midnight)} · ${city.name}'),
        _line('Your equivalent', '${DateFormat('d MMM h:mm a').format(viewerEquivalent)} · ${viewerCity.name}'),
        _line('Age', 'Unknown — no birth year provided'),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PersonDetailScreen(payload: PersonRoutePayload(personName: person.name, viewerName: viewer.name)))), child: const Text('Open person')),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.pt.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: context.pt.outline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900))]), const SizedBox(height: 12), ...children]),
      );
}

Widget _line(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 112, child: Text(label, style: const TextStyle(fontSize: 11))), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)))]));

FamilyMember _member(String name) => familyMembers.firstWhere((member) => _normal(member.name) == _normal(name), orElse: () => familyMembers.first);
FamilyCity _city(String id) => cities.firstWhere((city) => city.id == id);
String _normal(String value) => value.replaceAll('İ', 'I').toLowerCase();
DateTime? _birthday(String name) { final found = familyBirthdays.where((item) => _normal(item.name) == _normal(name)); if (found.isEmpty) return null; final item = found.first; return DateTime(DateTime.now().year, item.month, item.day); }
DateTime _nextBirthday(DateTime birthday) { final now = DateTime.now(); var next = DateTime(now.year, birthday.month, birthday.day); if (next.isBefore(DateTime(now.year, now.month, now.day))) next = DateTime(now.year + 1, birthday.month, birthday.day); return next; }
int _daysUntil(DateTime birthday) => _nextBirthday(birthday).difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;
String _offsetText(Duration difference) { if (difference == Duration.zero) return 'Same time'; final h = difference.inMinutes.abs() ~/ 60; final m = difference.inMinutes.abs() % 60; return '${h}h${m == 0 ? '' : ' ${m}m'} ${difference.isNegative ? 'behind' : 'ahead'}'; }
DateTime _nextFree(FamilyMember member, FamilyCity city) { final now = DateTime.now().toUtc(); for (var i = 1; i <= 192; i++) { final candidate = now.add(Duration(minutes: i * 15)); if (evaluateAvailability(member: member, city: city, now: candidate).kind == AvailabilityKind.likelyFree) return candidate; } return now.add(const Duration(days: 2)); }
String _nextClockChange(String timezone) { final location = tz.getLocation(timezone); final now = tz.TZDateTime.now(location); final offset = now.timeZoneOffset; for (var day = 1; day <= 400; day++) { final probe = now.add(Duration(days: day)); if (probe.timeZoneOffset != offset) return '${DateFormat('d MMM yyyy').format(probe)} · clocks change by ${(probe.timeZoneOffset - offset).inMinutes} min'; } return 'No clock change in the next year'; }
String _holidayContext(String country, DateTime local) { final holidays = _holidayRecords.where((item) => item.country == country && item.date.month == local.month && item.date.day >= local.day).toList()..sort((a,b) => a.date.day.compareTo(b.date.day)); return holidays.isEmpty ? 'No listed national holiday later this month' : '${holidays.first.officialName} · ${DateFormat('d MMM').format(holidays.first.date)}. Routine impact is not assumed.'; }
String _contactRecommendation(FamilyMember person, AvailabilitySnapshot value, DateTime next) => value.kind == AvailabilityKind.likelyFree ? '${person.name} may be free now because ${value.reason.toLowerCase()} This is a routine estimate, not live activity.' : 'Try around ${DateFormat('EEE h:mm a').format(next)}. The estimate uses the saved routine, not live activity.';
IconData _routineIcon(AvailabilityKind kind) => switch (kind) { AvailabilityKind.asleep => Icons.bedtime_outlined, AvailabilityKind.working => Icons.work_outline, AvailabilityKind.likelyFree => Icons.call_outlined, AvailabilityKind.maybeFree => Icons.help_outline, AvailabilityKind.unknown => Icons.question_mark_rounded };
String _minutes(int value) => '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
String _weekdayText(Set<int>? values) => values == null ? 'Every day' : values.map((value) => DateFormat('EEE').format(DateTime(2026, 8, 3 + value - 1))).join(', ');
Future<void> _recordThinkingOfYou(BuildContext context, String name) async { final prefs = await SharedPreferences.getInstance(); await prefs.setString('thinking_$name', DateTime.now().toIso8601String()); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved locally: thinking of $name'))); }

class _PlannerOption { const _PlannerOption(this.utc, this.rating, this.explanation); final DateTime utc; final String rating; final String explanation; }
List<_PlannerOption> _scoreWindows(Set<String> names, DateTime date, int earliest, int latest) { final selected = names.map(_member).toList(); final options = <_PlannerOption>[]; for (var hour = 0; hour < 24; hour++) { final utc = DateTime.utc(date.year, date.month, date.day, hour); var comfortable = 0; var acceptable = 0; var sleeping = 0; final details = <String>[]; for (final person in selected) { final city = _city(person.cityId); final local = tz.TZDateTime.from(utc, tz.getLocation(city.timezone)); final availability = evaluateAvailability(member: person, city: city, now: utc); final within = local.hour >= earliest && local.hour < latest; if (availability.kind == AvailabilityKind.likelyFree && within) comfortable++; else if (availability.kind != AvailabilityKind.asleep && within) acceptable++; else sleeping++; details.add('${person.name} ${DateFormat('h a').format(local)}'); } final rating = sleeping == 0 && comfortable == selected.length ? 'Comfortable' : sleeping == 0 && comfortable + acceptable == selected.length ? 'Acceptable' : 'Difficult'; options.add(_PlannerOption(utc, rating, '${details.join(' · ')}. $comfortable likely free, $acceptable uncertain, $sleeping outside boundaries or asleep.')); } const rank = {'Comfortable': 0, 'Acceptable': 1, 'Difficult': 2}; options.sort((a,b) => rank[a.rating]!.compareTo(rank[b.rating]!)); return options; }
Future<void> _saveCall(BuildContext context, DateTime utc) async { await FamilyEventStore().add(FamilyEvent(id: DateTime.now().microsecondsSinceEpoch.toString(), title: 'Planned family call', type: FamilyEventType.familyCall, utcStart: utc, timezone: 'UTC', participants: familyMembers.take(3).map((member) => member.name).toList())); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Family call saved to the calendar'))); }

class _HolidayRecord { const _HolidayRecord(this.country, this.officialName, this.translatedName, this.date); final String country; final String officialName; final String translatedName; final DateTime date; }
final _holidayRecords = <_HolidayRecord>[
  _HolidayRecord('Pakistan', 'Pakistan Day', 'Pakistan Day', DateTime(2026, 3, 23)),
  _HolidayRecord('Pakistan', 'Independence Day', 'Independence Day', DateTime(2026, 8, 14)),
  _HolidayRecord('Japan', '建国記念の日', 'National Foundation Day', DateTime(2026, 2, 11)),
  _HolidayRecord('Japan', '文化の日', 'Culture Day', DateTime(2026, 11, 3)),
  _HolidayRecord('Ireland', "Saint Patrick's Day", "Saint Patrick's Day", DateTime(2026, 3, 17)),
  _HolidayRecord('Ireland', 'Christmas Day', 'Christmas Day', DateTime(2026, 12, 25)),
  _HolidayRecord('United States', 'Independence Day', 'Independence Day', DateTime(2026, 7, 4)),
  _HolidayRecord('United States', 'Thanksgiving Day', 'Thanksgiving Day', DateTime(2026, 11, 26)),
];

List<String> _calendarLabels(DateTime date, List<FamilyEvent> events, String filter) { final labels = <String>[]; if (filter == 'All' || filter == 'Birthdays') { for (final birthday in familyBirthdays) { if (birthday.month == date.month && birthday.day == date.day) labels.add('🎂 ${birthday.name}'); } } if (filter == 'All' || filter == 'Holidays') { for (final holiday in _holidayRecords) { if (holiday.date.month == date.month && holiday.date.day == date.day) labels.add('• ${holiday.translatedName}'); } } if (filter == 'All' || filter == 'Family events') { for (final event in events) { final local = event.utcStart.toLocal(); if (local.year == date.year && local.month == date.month && local.day == date.day) labels.add('◦ ${event.title}'); } } return labels; }
class _AgendaItem { const _AgendaItem(this.icon, this.title, this.subtitle); final IconData icon; final String title; final String subtitle; }
List<_AgendaItem> _agenda(List<FamilyEvent> events) { final now = DateTime.now(); final items = <_AgendaItem>[]; for (final birthday in familyBirthdays) { final date = _nextBirthday(DateTime(now.year, birthday.month, birthday.day)); items.add(_AgendaItem(Icons.cake_outlined, birthday.name, DateFormat('d MMMM').format(date))); } for (final event in events.where((event) => event.utcStart.isAfter(now.toUtc()))) { items.add(_AgendaItem(Icons.event_outlined, event.title, DateFormat('d MMM · h:mm a').format(event.utcStart.toLocal()))); } items.sort((a,b) => a.subtitle.compareTo(b.subtitle)); return items.take(15).toList(); }

extension _FirstOrNull<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }
