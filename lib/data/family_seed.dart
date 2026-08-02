enum AvailabilityKind { asleep, working, likelyFree, maybeFree, unknown }

enum ConfidenceLevel { high, medium, low }

class TimeBand {
  const TimeBand({
    required this.startMinute,
    required this.endMinute,
    required this.kind,
    required this.reason,
    this.confidence = ConfidenceLevel.medium,
    this.weekdays,
  });

  final int startMinute;
  final int endMinute;
  final AvailabilityKind kind;
  final String reason;
  final ConfidenceLevel confidence;
  final Set<int>? weekdays;

  bool applies(int weekday, int minute) {
    if (weekdays != null && !weekdays!.contains(weekday)) return false;
    if (startMinute == endMinute) return true;
    if (endMinute > startMinute) {
      return minute >= startMinute && minute < endMinute;
    }
    return minute >= startMinute || minute < endMinute;
  }
}

class RoutineProfile {
  const RoutineProfile({required this.bands, required this.summary});

  final List<TimeBand> bands;
  final String summary;
}

class FamilyMember {
  const FamilyMember({
    required this.name,
    required this.relationship,
    required this.cityId,
    required this.initials,
    required this.routine,
  });

  final String name;
  final String relationship;
  final String cityId;
  final String initials;
  final RoutineProfile routine;
}

class FamilyCity {
  const FamilyCity({
    required this.id,
    required this.name,
    required this.country,
    required this.timezone,
    required this.asset,
    required this.weatherLine,
  });

  final String id;
  final String name;
  final String country;
  final String timezone;
  final String asset;
  final String weatherLine;
}

int hm(int hour, [int minute = 0]) => hour * 60 + minute;

const weekdays = {DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday};
const weekends = {DateTime.saturday, DateTime.sunday};

RoutineProfile karachiEarlyWorker(String name) => RoutineProfile(
  summary: '$name usually works 6:00 AM–4:00 PM on weekdays and is generally free afterward until midnight. Weekend availability follows the family’s usual 11:00 AM–11:00 PM waking window.',
  bands: [
    TimeBand(startMinute: hm(0), endMinute: hm(5), kind: AvailabilityKind.asleep, reason: 'Usually sleeping before an early workday.', confidence: ConfidenceLevel.high, weekdays: weekdays),
    TimeBand(startMinute: hm(5), endMinute: hm(6), kind: AvailabilityKind.maybeFree, reason: 'Likely awake and getting ready for work.', weekdays: weekdays),
    TimeBand(startMinute: hm(6), endMinute: hm(16), kind: AvailabilityKind.working, reason: 'Inside the usual 6:00 AM–4:00 PM work schedule.', confidence: ConfidenceLevel.high, weekdays: weekdays),
    TimeBand(startMinute: hm(16), endMinute: hm(24), kind: AvailabilityKind.likelyFree, reason: 'Usually finished with work and awake until midnight.', confidence: ConfidenceLevel.high, weekdays: weekdays),
    TimeBand(startMinute: hm(0), endMinute: hm(11), kind: AvailabilityKind.asleep, reason: 'The family usually sleeps later on weekends.', confidence: ConfidenceLevel.medium, weekdays: weekends),
    TimeBand(startMinute: hm(11), endMinute: hm(23), kind: AvailabilityKind.likelyFree, reason: 'Inside the usual weekend waking window.', weekdays: weekends),
    TimeBand(startMinute: hm(23), endMinute: hm(24), kind: AvailabilityKind.asleep, reason: 'Usually winding down after 11:00 PM on weekends.', weekdays: weekends),
  ],
);

RoutineProfile karachiOfficeWorker(String name) => RoutineProfile(
  summary: '$name usually works 8:00 AM–5:00 PM on weekdays and is generally free afterward until midnight. Weekend availability follows the family’s usual 11:00 AM–11:00 PM waking window.',
  bands: [
    TimeBand(startMinute: hm(0), endMinute: hm(7), kind: AvailabilityKind.asleep, reason: 'Usually sleeping before the office day.', confidence: ConfidenceLevel.high, weekdays: weekdays),
    TimeBand(startMinute: hm(7), endMinute: hm(8), kind: AvailabilityKind.maybeFree, reason: 'Likely awake and preparing for the office.', weekdays: weekdays),
    TimeBand(startMinute: hm(8), endMinute: hm(17), kind: AvailabilityKind.working, reason: 'Inside the usual 8:00 AM–5:00 PM office schedule.', confidence: ConfidenceLevel.high, weekdays: weekdays),
    TimeBand(startMinute: hm(17), endMinute: hm(24), kind: AvailabilityKind.likelyFree, reason: 'Usually home from the office and awake.', confidence: ConfidenceLevel.high, weekdays: weekdays),
    TimeBand(startMinute: hm(0), endMinute: hm(11), kind: AvailabilityKind.asleep, reason: 'The family usually sleeps later on weekends.', weekdays: weekends),
    TimeBand(startMinute: hm(11), endMinute: hm(23), kind: AvailabilityKind.likelyFree, reason: 'Inside the usual weekend waking window.', weekdays: weekends),
    TimeBand(startMinute: hm(23), endMinute: hm(24), kind: AvailabilityKind.asleep, reason: 'Usually winding down after 11:00 PM.', weekdays: weekends),
  ],
);

RoutineProfile karachiGenerallyFree(String name) => RoutineProfile(
  summary: '$name is generally treated as awake and likely free from 10:00 AM until midnight on weekdays. On weekends, the family’s usual waking window is 11:00 AM–11:00 PM. This is a broad estimate, not a live status.',
  bands: [
    TimeBand(startMinute: hm(0), endMinute: hm(10), kind: AvailabilityKind.asleep, reason: 'Outside the stated weekday waking window.', confidence: ConfidenceLevel.medium, weekdays: weekdays),
    TimeBand(startMinute: hm(10), endMinute: hm(24), kind: AvailabilityKind.likelyFree, reason: 'Inside the broad 10:00 AM–midnight free window.', confidence: ConfidenceLevel.medium, weekdays: weekdays),
    TimeBand(startMinute: hm(0), endMinute: hm(11), kind: AvailabilityKind.asleep, reason: 'The family usually sleeps later on weekends.', weekdays: weekends),
    TimeBand(startMinute: hm(11), endMinute: hm(23), kind: AvailabilityKind.likelyFree, reason: 'Inside the usual weekend waking window.', weekdays: weekends),
    TimeBand(startMinute: hm(23), endMinute: hm(24), kind: AvailabilityKind.asleep, reason: 'Usually asleep after the weekend waking window.', weekdays: weekends),
  ],
);

final ramshaRoutine = RoutineProfile(
  summary: 'Ramsha usually works 8:00 AM–4:00 PM, is generally free afterward, and sleeps around midnight. Weekend availability follows the family’s usual 11:00 AM–11:00 PM waking window.',
  bands: [
    TimeBand(startMinute: hm(0), endMinute: hm(7), kind: AvailabilityKind.asleep, reason: 'Usually sleeping.', confidence: ConfidenceLevel.high, weekdays: weekdays),
    TimeBand(startMinute: hm(7), endMinute: hm(8), kind: AvailabilityKind.maybeFree, reason: 'Likely awake and getting ready for work.', weekdays: weekdays),
    TimeBand(startMinute: hm(8), endMinute: hm(16), kind: AvailabilityKind.working, reason: 'Inside her usual 8:00 AM–4:00 PM work schedule.', confidence: ConfidenceLevel.high, weekdays: weekdays),
    TimeBand(startMinute: hm(16), endMinute: hm(24), kind: AvailabilityKind.likelyFree, reason: 'Usually finished with work and awake until midnight.', confidence: ConfidenceLevel.high, weekdays: weekdays),
    TimeBand(startMinute: hm(0), endMinute: hm(11), kind: AvailabilityKind.asleep, reason: 'Usually sleeping during the late weekend morning.', weekdays: weekends),
    TimeBand(startMinute: hm(11), endMinute: hm(23), kind: AvailabilityKind.likelyFree, reason: 'Inside the family’s usual weekend waking window.', weekdays: weekends),
    TimeBand(startMinute: hm(23), endMinute: hm(24), kind: AvailabilityKind.maybeFree, reason: 'May still be awake, but the weekend window is ending.', confidence: ConfidenceLevel.low, weekdays: weekends),
  ],
);

final salmanRoutine = RoutineProfile(
  summary: 'Salman usually works from home 9:00 AM–5:00 PM. He may be occupied during those hours, but working from home makes certainty lower. From 5:00 PM–11:00 PM he is off work and may be free.',
  bands: [
    TimeBand(startMinute: hm(0), endMinute: hm(8), kind: AvailabilityKind.asleep, reason: 'Probably sleeping before the workday.', confidence: ConfidenceLevel.medium),
    TimeBand(startMinute: hm(8), endMinute: hm(9), kind: AvailabilityKind.maybeFree, reason: 'Likely awake before work.', confidence: ConfidenceLevel.medium),
    TimeBand(startMinute: hm(9), endMinute: hm(17), kind: AvailabilityKind.maybeFree, reason: 'Working from home: he may be busy, but the app cannot know whether he is in a meeting or available.', confidence: ConfidenceLevel.low, weekdays: weekdays),
    TimeBand(startMinute: hm(17), endMinute: hm(23), kind: AvailabilityKind.maybeFree, reason: 'Usually off work, though not necessarily available.', confidence: ConfidenceLevel.medium, weekdays: weekdays),
    TimeBand(startMinute: hm(23), endMinute: hm(24), kind: AvailabilityKind.asleep, reason: 'Usually sleeping after 11:00 PM.', confidence: ConfidenceLevel.medium),
    TimeBand(startMinute: hm(9), endMinute: hm(23), kind: AvailabilityKind.maybeFree, reason: 'Likely awake on the weekend, but no precise availability was provided.', confidence: ConfidenceLevel.low, weekdays: weekends),
  ],
);

final asmaRoutine = RoutineProfile(
  summary: 'Asma usually works 9:00 AM–4:00 PM and sleeps around 9:00 PM. She is reliably available to call from 7:00–9:00 AM. On weekends she usually wakes around 7:00 AM.',
  bands: [
    TimeBand(startMinute: hm(0), endMinute: hm(7), kind: AvailabilityKind.asleep, reason: 'Usually sleeping.', confidence: ConfidenceLevel.high),
    TimeBand(startMinute: hm(7), endMinute: hm(9), kind: AvailabilityKind.likelyFree, reason: 'Her stated reliable calling window is 7:00–9:00 AM.', confidence: ConfidenceLevel.high),
    TimeBand(startMinute: hm(9), endMinute: hm(16), kind: AvailabilityKind.working, reason: 'Inside her usual 9:00 AM–4:00 PM work schedule.', confidence: ConfidenceLevel.high, weekdays: weekdays),
    TimeBand(startMinute: hm(16), endMinute: hm(21), kind: AvailabilityKind.maybeFree, reason: 'Usually finished with work and awake, but not explicitly confirmed as free.', confidence: ConfidenceLevel.medium, weekdays: weekdays),
    TimeBand(startMinute: hm(9), endMinute: hm(21), kind: AvailabilityKind.maybeFree, reason: 'Awake on the weekend, but only 7:00–9:00 AM is confirmed as a reliable call window.', confidence: ConfidenceLevel.low, weekdays: weekends),
    TimeBand(startMinute: hm(21), endMinute: hm(24), kind: AvailabilityKind.asleep, reason: 'She normally sleeps at 9:00 PM.', confidence: ConfidenceLevel.high),
  ],
);

final hasanRoutine = RoutineProfile(
  summary: 'Hasan is busy Monday and Wednesday from 8:00 AM–5:30 PM. Between 5:30–9:00 PM he may be free; after 9:00 PM he is reliably free until about 3:00 AM. On other days, daytime availability is uncertain.',
  bands: [
    TimeBand(startMinute: hm(3), endMinute: hm(8), kind: AvailabilityKind.asleep, reason: 'Likely sleeping before an early class day.', confidence: ConfidenceLevel.medium, weekdays: {DateTime.monday, DateTime.wednesday}),
    TimeBand(startMinute: hm(8), endMinute: hm(17, 30), kind: AvailabilityKind.working, reason: 'Inside the stated Monday/Wednesday busy block.', confidence: ConfidenceLevel.high, weekdays: {DateTime.monday, DateTime.wednesday}),
    TimeBand(startMinute: hm(17, 30), endMinute: hm(21), kind: AvailabilityKind.maybeFree, reason: 'Classes are over, but work or other commitments may continue.', confidence: ConfidenceLevel.low, weekdays: {DateTime.monday, DateTime.wednesday}),
    TimeBand(startMinute: hm(21), endMinute: hm(3), kind: AvailabilityKind.likelyFree, reason: 'Inside his stated reliable 9:00 PM–3:00 AM free window.', confidence: ConfidenceLevel.high),
    TimeBand(startMinute: hm(3), endMinute: hm(10), kind: AvailabilityKind.asleep, reason: 'Likely sleeping after the late-night free window.', confidence: ConfidenceLevel.medium, weekdays: {DateTime.tuesday, DateTime.thursday, DateTime.friday, DateTime.saturday, DateTime.sunday}),
    TimeBand(startMinute: hm(10), endMinute: hm(21), kind: AvailabilityKind.maybeFree, reason: 'He may be working or free; there is not enough information to claim either.', confidence: ConfidenceLevel.low, weekdays: {DateTime.tuesday, DateTime.thursday, DateTime.friday, DateTime.saturday, DateTime.sunday}),
  ],
);

const cities = <FamilyCity>[
  FamilyCity(id: 'karachi', name: 'Karachi', country: 'Pakistan', timezone: 'Asia/Karachi', asset: 'assets/cities/karachi.svg', weatherLine: 'Monsoon season · warm coastal air'),
  FamilyCity(id: 'chiba', name: 'Chiba', country: 'Japan', timezone: 'Asia/Tokyo', asset: 'assets/cities/chiba.svg', weatherLine: 'Pacific evening · summer rain'),
  FamilyCity(id: 'dublin', name: 'Dublin', country: 'Ireland', timezone: 'Europe/Dublin', asset: 'assets/cities/dublin.svg', weatherLine: 'Cool Atlantic light · shifting clouds'),
  FamilyCity(id: 'hattiesburg', name: 'Hattiesburg', country: 'United States', timezone: 'America/Chicago', asset: 'assets/cities/hattiesburg.svg', weatherLine: 'Deep summer · pine-country air'),
];

final familyMembers = <FamilyMember>[
  FamilyMember(name: 'Hasan', relationship: 'Me', cityId: 'hattiesburg', initials: 'HB', routine: hasanRoutine),
  FamilyMember(name: 'Ramsha', relationship: 'Sister', cityId: 'karachi', initials: 'RB', routine: ramshaRoutine),
  FamilyMember(name: 'Salman', relationship: 'Brother', cityId: 'dublin', initials: 'SB', routine: salmanRoutine),
  FamilyMember(name: 'Talat', relationship: 'Mother', cityId: 'karachi', initials: 'TB', routine: karachiEarlyWorker('Talat')),
  FamilyMember(name: 'Shahid', relationship: 'Father', cityId: 'karachi', initials: 'SH', routine: karachiGenerallyFree('Shahid')),
  FamilyMember(name: 'Nighat', relationship: 'Aunt', cityId: 'karachi', initials: 'NB', routine: karachiEarlyWorker('Nighat')),
  FamilyMember(name: 'İmran', relationship: 'Uncle', cityId: 'karachi', initials: 'IB', routine: karachiOfficeWorker('İmran')),
  FamilyMember(name: 'Raffat', relationship: 'Aunt', cityId: 'karachi', initials: 'RF', routine: karachiEarlyWorker('Raffat')),
  FamilyMember(name: 'Yasin', relationship: 'Uncle', cityId: 'karachi', initials: 'YB', routine: karachiOfficeWorker('Yasin')),
  FamilyMember(name: 'Affan', relationship: 'Cousin', cityId: 'karachi', initials: 'AB', routine: karachiGenerallyFree('Affan')),
  FamilyMember(name: 'Sarwat', relationship: 'Aunt', cityId: 'karachi', initials: 'SW', routine: karachiGenerallyFree('Sarwat')),
  FamilyMember(name: 'Asma', relationship: 'Aunt', cityId: 'chiba', initials: 'AS', routine: asmaRoutine),
  FamilyMember(name: 'Ami', relationship: 'Grandmother', cityId: 'karachi', initials: 'AM', routine: karachiGenerallyFree('Ami')),
  FamilyMember(name: 'Nanu', relationship: 'Grandfather', cityId: 'karachi', initials: 'NA', routine: karachiGenerallyFree('Nanu')),
];
