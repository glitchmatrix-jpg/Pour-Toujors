import 'package:flutter/material.dart';

import '../../core/identity/identity_store.dart';
import '../home/premium_home_screen.dart';
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
    if (!mounted) return;
    setState(() {
      selected = value;
      loading = false;
    });
  }

  Future<void> _select(String name) async {
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
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6F3),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (selected == null) return IdentitySetupScreen(onSelected: _select);
    return PremiumHomeScreen(viewerName: selected!, onSwitchProfile: _switchProfile);
  }
}
