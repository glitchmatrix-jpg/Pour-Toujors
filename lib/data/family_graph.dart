import 'package:flutter/material.dart';

import '../app/theme/pour_toujours_theme.dart';

enum FamilyGender { female, male, unspecified }

enum FamilyLinkType { parent, spouse, sibling }

class FamilyLink {
  const FamilyLink({
    required this.first,
    required this.second,
    required this.type,
  });

  final String first;
  final String second;
  final FamilyLinkType type;
}

class FamilyGraph {
  const FamilyGraph({
    required this.genders,
    required this.links,
    required this.missingLinks,
  });

  final Map<String, FamilyGender> genders;
  final List<FamilyLink> links;
  final List<String> missingLinks;

  String relationship({required String viewer, required String person}) {
    if (_same(viewer, person)) return 'You';

    if (_areSpouses(viewer, person)) {
      return _gendered(
        person,
        female: 'Wife',
        male: 'Husband',
        other: 'Spouse',
      );
    }
    if (_isParent(viewer, person)) {
      return _gendered(
        person,
        female: 'Daughter',
        male: 'Son',
        other: 'Child',
      );
    }
    if (_isParent(person, viewer)) {
      return _gendered(
        person,
        female: 'Mother',
        male: 'Father',
        other: 'Parent',
      );
    }
    if (_areSiblings(viewer, person)) {
      return _gendered(
        person,
        female: 'Sister',
        male: 'Brother',
        other: 'Sibling',
      );
    }
    if (_isGrandparent(person, viewer)) {
      return _gendered(
        person,
        female: 'Grandmother',
        male: 'Grandfather',
        other: 'Grandparent',
      );
    }
    if (_isGrandparent(viewer, person)) {
      return _gendered(
        person,
        female: 'Granddaughter',
        male: 'Grandson',
        other: 'Grandchild',
      );
    }

    final viewerSpouse = _spouseOf(viewer);
    final personSpouse = _spouseOf(person);

    if (viewerSpouse != null && _isParent(person, viewerSpouse)) {
      return _gendered(
        person,
        female: 'Mother-in-law',
        male: 'Father-in-law',
        other: 'Parent-in-law',
      );
    }
    if (personSpouse != null && _isParent(viewer, personSpouse)) {
      return _gendered(
        person,
        female: 'Daughter-in-law',
        male: 'Son-in-law',
        other: 'Child-in-law',
      );
    }
    if (personSpouse != null && _areSiblings(viewer, personSpouse)) {
      return _gendered(
        person,
        female: 'Sister-in-law',
        male: 'Brother-in-law',
        other: 'Sibling-in-law',
      );
    }
    if (viewerSpouse != null && _areSiblings(viewerSpouse, person)) {
      return _gendered(
        person,
        female: 'Sister-in-law',
        male: 'Brother-in-law',
        other: 'Sibling-in-law',
      );
    }

    if (_isAuntOrUncle(person, viewer)) {
      return _gendered(
        person,
        female: 'Aunt',
        male: 'Uncle',
        other: 'Parent’s sibling',
      );
    }
    if (personSpouse != null && _isAuntOrUncle(personSpouse, viewer)) {
      return _gendered(
        person,
        female: 'Aunt by marriage',
        male: 'Uncle by marriage',
        other: 'Aunt or uncle by marriage',
      );
    }
    if (_isAuntOrUncle(viewer, person)) {
      return _gendered(
        person,
        female: 'Niece',
        male: 'Nephew',
        other: 'Sibling’s child',
      );
    }
    if (viewerSpouse != null && _isAuntOrUncle(viewerSpouse, person)) {
      return _gendered(
        person,
        female: 'Niece by marriage',
        male: 'Nephew by marriage',
        other: 'Niece or nephew by marriage',
      );
    }
    if (_areCousins(viewer, person)) return 'Cousin';

    return 'Relationship not mapped';
  }

  bool _isParent(String parent, String child) => links.any(
        (link) =>
            link.type == FamilyLinkType.parent &&
            _same(link.first, parent) &&
            _same(link.second, child),
      );

  bool _areSpouses(String first, String second) => links.any(
        (link) =>
            link.type == FamilyLinkType.spouse &&
            ((_same(link.first, first) && _same(link.second, second)) ||
                (_same(link.first, second) && _same(link.second, first))),
      );

  bool _areSiblings(String first, String second) {
    if (_same(first, second)) return false;
    if (links.any(
      (link) =>
          link.type == FamilyLinkType.sibling &&
          ((_same(link.first, first) && _same(link.second, second)) ||
              (_same(link.first, second) && _same(link.second, first))),
    )) {
      return true;
    }
    return _parentsOf(first).intersection(_parentsOf(second)).isNotEmpty;
  }

  bool _isGrandparent(String grandparent, String child) {
    for (final parent in _parentsOf(child)) {
      if (_isParent(grandparent, parent)) return true;
    }
    return false;
  }

  bool _isAuntOrUncle(String candidate, String person) {
    for (final parent in _parentsOf(person)) {
      if (_areSiblings(candidate, parent)) return true;
    }
    return false;
  }

  bool _areCousins(String first, String second) {
    for (final firstParent in _parentsOf(first)) {
      for (final secondParent in _parentsOf(second)) {
        if (_areSiblings(firstParent, secondParent)) return true;
      }
    }
    return false;
  }

  Set<String> _parentsOf(String child) => links
      .where(
        (link) =>
            link.type == FamilyLinkType.parent && _same(link.second, child),
      )
      .map((link) => link.first)
      .toSet();

  String? _spouseOf(String person) {
    for (final link in links.where((link) => link.type == FamilyLinkType.spouse)) {
      if (_same(link.first, person)) return link.second;
      if (_same(link.second, person)) return link.first;
    }
    return null;
  }

  String _gendered(
    String name, {
    required String female,
    required String male,
    required String other,
  }) {
    return switch (genders[_normal(name)] ?? FamilyGender.unspecified) {
      FamilyGender.female => female,
      FamilyGender.male => male,
      FamilyGender.unspecified => other,
    };
  }

  static bool _same(String first, String second) =>
      _normal(first) == _normal(second);

  static String _normal(String value) =>
      value.replaceAll('İ', 'I').trim().toLowerCase();
}

const familyGraph = FamilyGraph(
  genders: {
    'hasan': FamilyGender.male,
    'ramsha': FamilyGender.female,
    'salman': FamilyGender.male,
    'talat': FamilyGender.female,
    'shahid': FamilyGender.male,
    'nighat': FamilyGender.female,
    'imran': FamilyGender.male,
    'raffat': FamilyGender.female,
    'yasin': FamilyGender.male,
    'affan': FamilyGender.male,
    'sarwat': FamilyGender.female,
    'asma': FamilyGender.female,
    'ami': FamilyGender.female,
    'nanu': FamilyGender.male,
  },
  links: [
    FamilyLink(first: 'Ami', second: 'Nanu', type: FamilyLinkType.spouse),
    FamilyLink(first: 'Ami', second: 'Talat', type: FamilyLinkType.parent),
    FamilyLink(first: 'Nanu', second: 'Talat', type: FamilyLinkType.parent),
    FamilyLink(first: 'Ami', second: 'Nighat', type: FamilyLinkType.parent),
    FamilyLink(first: 'Nanu', second: 'Nighat', type: FamilyLinkType.parent),
    FamilyLink(first: 'Ami', second: 'İmran', type: FamilyLinkType.parent),
    FamilyLink(first: 'Nanu', second: 'İmran', type: FamilyLinkType.parent),
    FamilyLink(first: 'Ami', second: 'Raffat', type: FamilyLinkType.parent),
    FamilyLink(first: 'Nanu', second: 'Raffat', type: FamilyLinkType.parent),
    FamilyLink(first: 'Ami', second: 'Yasin', type: FamilyLinkType.parent),
    FamilyLink(first: 'Nanu', second: 'Yasin', type: FamilyLinkType.parent),
    FamilyLink(first: 'Ami', second: 'Asma', type: FamilyLinkType.parent),
    FamilyLink(first: 'Nanu', second: 'Asma', type: FamilyLinkType.parent),
    FamilyLink(first: 'Talat', second: 'Shahid', type: FamilyLinkType.spouse),
    FamilyLink(first: 'Talat', second: 'Hasan', type: FamilyLinkType.parent),
    FamilyLink(first: 'Talat', second: 'Ramsha', type: FamilyLinkType.parent),
    FamilyLink(first: 'Talat', second: 'Salman', type: FamilyLinkType.parent),
    FamilyLink(first: 'Shahid', second: 'Hasan', type: FamilyLinkType.parent),
    FamilyLink(first: 'Shahid', second: 'Ramsha', type: FamilyLinkType.parent),
    FamilyLink(first: 'Shahid', second: 'Salman', type: FamilyLinkType.parent),
    FamilyLink(first: 'Yasin', second: 'Sarwat', type: FamilyLinkType.spouse),
    FamilyLink(first: 'Yasin', second: 'Affan', type: FamilyLinkType.parent),
    FamilyLink(first: 'Sarwat', second: 'Affan', type: FamilyLinkType.parent),
  ],
  missingLinks: [
    'Spouses and children for Nighat, İmran, Raffat, and Asma are not recorded.',
    'Birth years, preferred pronouns, and any additional relatives remain unknown unless supplied.',
  ],
);

extension PtThemeAccentAlias on PtThemeTokens {
  Color get accent => globeAccent;
}
