import 'package:flutter/material.dart';

import '../../core/identity/identity_store.dart';
import '../../data/family_seed.dart';
import '../home/premium_home_screen_v3.dart';
import 'identity_setup_screen.dart';

class IdentityGate extends StatefulWidget {
  const IdentityGate({super.key});

  @override
  State<IdentityGate> createState() => _IdentityGateState();
}

class _IdentityGateState extends State<IdentityGate> {
  final store = IdentityStore();
  String? selected;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await store.load();
    final valid = value != null &&
        familyMembers.any(
          (member) => member.name.toLowerCase() == value.toLowerCase(),
        );
    if (!valid && value != null) await store.clear();
    if (!mounted) return;
    setState(() {
      selected = valid
          ? familyMembers
              .firstWhere(
                (member) => member.name.toLowerCase() == value!.toLowerCase(),
              )
              .name
          : null;
      loading = false;
    });
  }

  Future<void> _select(String name) async {
    final valid = familyMembers.any((member) => member.name == name);
    if (!valid) return;
    await store.save(name);
    if (!mounted) return;
    setState(() => selected = name);
  }

  Future<void> _switchProfile() async {
    await store.clear();
    if (!mounted) return;
    setState(() => selected = null);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    if (selected == null) return IdentitySetupScreen(onSelected: _select);
    return PremiumHomeScreenV3(
      viewerName: selected!,
      onSwitchProfile: _switchProfile,
    );
  }
}
