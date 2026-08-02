import 'package:flutter/material.dart';

import '../app/theme/pour_toujours_theme.dart';
import 'family_seed.dart';

enum FamilyGender { female, male, unspecified }

enum FamilyLinkType { parent, spouse, custom }

class FamilyLink {
  const FamilyLink({
    required this.first,
    required this.second,
    required this.type,
    this.customFromFirst,
    this.customFromSecond,
  });

  final String first;
  final String second;
  final FamilyLinkType type;
  final String? customFromFirst;
  final String? customFromSecond;
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

  String relationship({
    required String viewer,
    required String person,
  }) {
    if (_same(viewer, person)) return 'You';

    final direct = _direct(viewer, person);
    if (direct != null) return direct;

    final viewerParents = _parentsOf(viewer);
    final personParents = _parentsOf(person);
    if (viewerParents.intersection(personParents).isNotEmpty) {
      return _gendered(person, female: 'Sister', male: 'Brother', other: 'Sibling');
    }

    if (_isParent(viewer, person)) {
      return _gendered(person, female: 'Daughter', male: 'Son', other: 'Child');
    }
    if (_isParent(person, viewer)) {
      return _gendered(person, female: 'Mother', male: 'Father', other: 'Parent');
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

    final spouse = _spouseOf(person);
    if (spouse != null && _isParent(spouse, viewer)) return 'Parent-in-law';
    if (spouse != null && _parentsOf(viewer).contains(spouse)) {
      return _gendered(
        person,
        female: 'Sister-in-law',
        male: 'Brother-in-law',
        other: 'In-law',
      );
    }

    final viewerParentSiblings = <String>{};
    for (final parent in viewerParents) {
      viewerParentSiblings.addAll(_siblingsOf(parent));
    }
    if (viewerParentSiblings.contains(person)) {
      return _gendered(
        person,
        female: 'Aunt',
        male: 'Uncle',
        other: 'Family member',
      );
    }
    if (viewerParentSiblings.contains(_spouseOf(person))) {
      return 'Aunt or uncle by marriage';
    }

    for (final sibling in _siblingsOf(viewer)) {
      if (_isParent(sibling, person)) {
        return _gendered(
          person,
          female: 'Niece',
          male: 'Nephew',
          other: 'Family member',
        );
      }
    }

    for (final auntOrUncle in viewerParentSiblings) {
      if (_isParent(auntOrUncle, person)) return 'Cousin';
    }

    return 'Family member';
  }

  String? _direct(String viewer, String person) {
    for (final link in links) {
      if (link.type == FamilyLinkType.custom) {
        if (_same(link.first, viewer) && _same(link.second, person)) {
          return link.customFromFirst;
        }
        if (_same(link.second, viewer) && _same(link.first, person)) {
          return link.customFromSecond;
        }
      }
      if (link.type == FamilyLinkType.spouse &&
          ((_same(link.first, viewer) && _same(link.second, person)) ||
              (_same(link.second, viewer) && _same(link.first, person)))) {
        return _gendered(person, female: 'Wife', male: 'Husband', other: 'Spouse');
      }
    }
    return null;
  }

  bool _isParent(String parent, String child) => links.any(
        (link) =>
            link.type == FamilyLinkType.parent &&
            _same(link.first, parent) &&
            _same(link.second, child),
      );

  bool _isGrandparent(String grandparent, String child) {
    for (final parent in _parentsOf(child)) {
      if (_isParent(grandparent, parent)) return true;
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

  Set<String> _siblingsOf(String person) {
    final parents = _parentsOf(person);
    if (parents.isEmpty) return const {};
    return familyMembers
        .where(
          (candidate) =>
              !_same(candidate.name, person) &&
              _parentsOf(candidate.name).intersection(parents).isNotEmpty,
        )
        .map((candidate) => candidate.name)
        .toSet();
  }

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
    FamilyLink(first: 'Talat', second: 'Hasan', type: FamilyLinkType.parent),
    FamilyLink(first: 'Talat', second: 'Ramsha', type: FamilyLinkType.parent),
    FamilyLink(first: 'Talat', second: 'Salman', type: FamilyLinkType.parent),
    FamilyLink(first: 'Shahid', second: 'Hasan', type: FamilyLinkType.parent),
    FamilyLink(first: 'Shahid', second: 'Ramsha', type: FamilyLinkType.parent),
    FamilyLink(first: 'Shahid', second: 'Salman', type: FamilyLinkType.parent),
    FamilyLink(first: 'Talat', second: 'Shahid', type: FamilyLinkType.spouse),
    FamilyLink(first: 'Ami', second: 'Talat', type: FamilyLinkType.parent),
    FamilyLink(first: 'Nanu', second: 'Talat', type: FamilyLinkType.parent),
    FamilyLink(first: 'Ami', second: 'Nanu', type: FamilyLinkType.spouse),
    FamilyLink(
      first: 'Hasan',
      second: 'Nighat',
      type: FamilyLinkType.custom,
      customFromFirst: 'Aunt',
      customFromSecond: 'Nephew',
    ),
    FamilyLink(
      first: 'Hasan',
      second: 'İmran',
      type: FamilyLinkType.custom,
      customFromFirst: 'Uncle',
      customFromSecond: 'Nephew',
    ),
    FamilyLink(
      first: 'Hasan',
      second: 'Raffat',
      type: FamilyLinkType.custom,
      customFromFirst: 'Aunt',
      customFromSecond: 'Nephew',
    ),
    FamilyLink(
      first: 'Hasan',
      second: 'Yasin',
      type: FamilyLinkType.custom,
      customFromFirst: 'Uncle',
      customFromSecond: 'Nephew',
    ),
    FamilyLink(
      first: 'Hasan',
      second: 'Affan',
      type: FamilyLinkType.custom,
      customFromFirst: 'Cousin',
      customFromSecond: 'Cousin',
    ),
    FamilyLink(
      first: 'Hasan',
      second: 'Sarwat',
      type: FamilyLinkType.custom,
      customFromFirst: 'Aunt',
      customFromSecond: 'Nephew',
    ),
    FamilyLink(
      first: 'Hasan',
      second: 'Asma',
      type: FamilyLinkType.custom,
      customFromFirst: 'Aunt',
      customFromSecond: 'Nephew',
    ),
  ],
  missingLinks: [
    'Parentage and spouse links for Nighat, Imran, Raffat, Yasin, Sarwat, Asma, and Affan are not recorded.',
    'The graph does not infer cousin or in-law relationships for viewers other than explicitly documented links.',
    'Birth years, preferred pronouns, and additional grandparents remain unknown unless supplied.',
  ],
);

extension PtThemeAccentAlias on PtThemeTokens {
  Color get accent => globeAccent;
}
