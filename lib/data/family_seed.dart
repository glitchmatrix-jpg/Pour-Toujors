enum Availability { free, maybeFree, busy, asleep }

class FamilyMember {
  const FamilyMember({
    required this.name,
    required this.relationship,
    required this.cityId,
    required this.initials,
    this.availability = Availability.maybeFree,
  });

  final String name;
  final String relationship;
  final String cityId;
  final String initials;
  final Availability availability;
}

class FamilyCity {
  const FamilyCity({
    required this.id,
    required this.name,
    required this.country,
    required this.timezone,
    required this.asset,
    required this.weatherLine,
    required this.timeLine,
  });

  final String id;
  final String name;
  final String country;
  final String timezone;
  final String asset;
  final String weatherLine;
  final String timeLine;
}

const cities = <FamilyCity>[
  FamilyCity(
    id: 'karachi',
    name: 'Karachi',
    country: 'Pakistan',
    timezone: 'Asia/Karachi',
    asset: 'assets/cities/karachi.svg',
    weatherLine: 'Warm afternoon · monsoon light',
    timeLine: 'The family home is awake',
  ),
  FamilyCity(
    id: 'chiba',
    name: 'Chiba',
    country: 'Japan',
    timezone: 'Asia/Tokyo',
    asset: 'assets/cities/chiba.svg',
    weatherLine: 'Soft evening · rain nearby',
    timeLine: 'Asma’s day is winding down',
  ),
  FamilyCity(
    id: 'dublin',
    name: 'Dublin',
    country: 'Ireland',
    timezone: 'Europe/Dublin',
    asset: 'assets/cities/dublin.svg',
    weatherLine: 'Cool morning · silver clouds',
    timeLine: 'Salman may be in his workday',
  ),
  FamilyCity(
    id: 'hattiesburg',
    name: 'Hattiesburg',
    country: 'United States',
    timezone: 'America/Chicago',
    asset: 'assets/cities/hattiesburg.svg',
    weatherLine: 'Quiet night · summer air',
    timeLine: 'Hasan is probably asleep',
  ),
];

const familyMembers = <FamilyMember>[
  FamilyMember(name: 'Hasan', relationship: 'Me', cityId: 'hattiesburg', initials: 'HB', availability: Availability.asleep),
  FamilyMember(name: 'Ramsha', relationship: 'Sister', cityId: 'karachi', initials: 'RB', availability: Availability.free),
  FamilyMember(name: 'Salman', relationship: 'Brother', cityId: 'dublin', initials: 'SB', availability: Availability.busy),
  FamilyMember(name: 'Talat', relationship: 'Mother', cityId: 'karachi', initials: 'TB', availability: Availability.free),
  FamilyMember(name: 'Shahid', relationship: 'Father', cityId: 'karachi', initials: 'SB', availability: Availability.maybeFree),
  FamilyMember(name: 'Nighat', relationship: 'Aunt', cityId: 'karachi', initials: 'NB'),
  FamilyMember(name: 'İmran', relationship: 'Uncle', cityId: 'karachi', initials: 'IB'),
  FamilyMember(name: 'Raffat', relationship: 'Aunt', cityId: 'karachi', initials: 'RB'),
  FamilyMember(name: 'Yasin', relationship: 'Uncle', cityId: 'karachi', initials: 'YB'),
  FamilyMember(name: 'Affan', relationship: 'Cousin', cityId: 'karachi', initials: 'AB', availability: Availability.free),
  FamilyMember(name: 'Sarwat', relationship: 'Aunt', cityId: 'karachi', initials: 'SB'),
  FamilyMember(name: 'Asma', relationship: 'Aunt', cityId: 'chiba', initials: 'AB', availability: Availability.maybeFree),
  FamilyMember(name: 'Ami', relationship: 'Grandmother', cityId: 'karachi', initials: 'AM', availability: Availability.free),
  FamilyMember(name: 'Nanu', relationship: 'Grandfather', cityId: 'karachi', initials: 'NA', availability: Availability.free),
];
