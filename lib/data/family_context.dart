import 'family_graph.dart';
import 'family_seed.dart';

class FamilyBirthday {
  const FamilyBirthday(this.name, this.month, this.day);
  final String name;
  final int month;
  final int day;

  DateTime nextOccurrence(DateTime now) {
    var date = DateTime(now.year, month, day);
    if (date.isBefore(DateTime(now.year, now.month, now.day))) {
      date = DateTime(now.year + 1, month, day);
    }
    return date;
  }
}

const familyBirthdays = <FamilyBirthday>[
  FamilyBirthday('Ramsha', 1, 15),
  FamilyBirthday('Nighat', 2, 19),
  FamilyBirthday('Sarwat', 3, 4),
  FamilyBirthday('Shahid', 3, 23),
  FamilyBirthday('Raffat', 3, 25),
  FamilyBirthday('Hasan', 5, 5),
  FamilyBirthday('Talat', 5, 25),
  FamilyBirthday('Imran', 7, 4),
  FamilyBirthday('Yasin', 8, 10),
  FamilyBirthday('Salman', 9, 28),
  FamilyBirthday('Affan', 11, 28),
];

String relationshipFor({
  required FamilyMember viewer,
  required FamilyMember person,
}) {
  return familyGraph.relationship(viewer: viewer.name, person: person.name);
}
