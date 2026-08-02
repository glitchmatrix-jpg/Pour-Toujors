import 'package:flutter_test/flutter_test.dart';

import 'package:pour_toujours/data/family_graph.dart';
import 'package:pour_toujours/data/family_seed.dart';

void main() {
  test('every family member sees themselves as You', () {
    for (final member in familyMembers) {
      expect(
        familyGraph.relationship(viewer: member.name, person: member.name),
        'You',
      );
    }
  });

  test('core relationships are viewer-relative in both directions', () {
    const expectations = <(String, String, String)>[
      ('Talat', 'Hasan', 'Son'),
      ('Hasan', 'Talat', 'Mother'),
      ('Shahid', 'Ramsha', 'Daughter'),
      ('Ramsha', 'Shahid', 'Father'),
      ('Hasan', 'Ramsha', 'Sister'),
      ('Ramsha', 'Hasan', 'Brother'),
      ('Salman', 'Hasan', 'Brother'),
      ('Hasan', 'Salman', 'Brother'),
      ('Talat', 'Shahid', 'Husband'),
      ('Shahid', 'Talat', 'Wife'),
      ('Yasin', 'Sarwat', 'Wife'),
      ('Sarwat', 'Yasin', 'Husband'),
      ('Yasin', 'Affan', 'Son'),
      ('Affan', 'Yasin', 'Father'),
      ('Sarwat', 'Affan', 'Son'),
      ('Affan', 'Sarwat', 'Mother'),
      ('Hasan', 'Affan', 'Cousin'),
      ('Affan', 'Hasan', 'Cousin'),
      ('Hasan', 'Nighat', 'Aunt'),
      ('Nighat', 'Hasan', 'Nephew'),
      ('Ramsha', 'İmran', 'Uncle'),
      ('İmran', 'Ramsha', 'Niece'),
      ('Salman', 'Asma', 'Aunt'),
      ('Asma', 'Salman', 'Nephew'),
      ('Talat', 'Nighat', 'Sister'),
      ('Nighat', 'Talat', 'Sister'),
      ('Talat', 'Yasin', 'Brother'),
      ('Yasin', 'Talat', 'Sister'),
      ('Ami', 'Talat', 'Daughter'),
      ('Talat', 'Ami', 'Mother'),
      ('Nanu', 'Yasin', 'Son'),
      ('Yasin', 'Nanu', 'Father'),
      ('Ami', 'Affan', 'Grandson'),
      ('Affan', 'Ami', 'Grandmother'),
      ('Shahid', 'Yasin', 'Brother-in-law'),
      ('Yasin', 'Shahid', 'Brother-in-law'),
      ('Talat', 'Sarwat', 'Sister-in-law'),
      ('Sarwat', 'Talat', 'Sister-in-law'),
      ('Shahid', 'Affan', 'Nephew by marriage'),
      ('Affan', 'Shahid', 'Uncle by marriage'),
    ];

    for (final (viewer, person, expected) in expectations) {
      expect(
        familyGraph.relationship(viewer: viewer, person: person),
        expected,
        reason: '$viewer should see $person as $expected',
      );
    }
  });

  test('the mapped family never falls back to a Hasan-centric default', () {
    for (final viewer in familyMembers) {
      for (final person in familyMembers) {
        final relationship = familyGraph.relationship(
          viewer: viewer.name,
          person: person.name,
        );
        expect(relationship, isNot('Family member'));
        expect(relationship, isNotEmpty);
      }
    }
  });
}
