import 'package:flutter/material.dart';

import '../../data/family_seed.dart';

class IdentitySetupScreen extends StatefulWidget {
  const IdentitySetupScreen({super.key, required this.onSelected});

  final Future<void> Function(String name) onSelected;

  @override
  State<IdentitySetupScreen> createState() => _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends State<IdentitySetupScreen> {
  String? selected;
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F4),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF102A2C),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.public_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Pour Toujours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Who are you?',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Choose once. Times, call windows, weather context, and reminders will be shown relative to you.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF5E6665),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    flex: 5,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 190,
                        mainAxisExtent: 112,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: familyMembers.length,
                      itemBuilder: (context, index) {
                        final member = familyMembers[index];
                        final active = selected == member.name;
                        return InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => setState(() => selected = member.name),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF102A2C)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF102A2C)
                                    : const Color(0xFFE2E5E0),
                              ),
                              boxShadow: active
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x24102A2C),
                                        blurRadius: 20,
                                        offset: Offset(0, 8),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: active
                                      ? Colors.white12
                                      : const Color(0xFFE9EFEC),
                                  foregroundColor: active
                                      ? Colors.white
                                      : const Color(0xFF102A2C),
                                  child: Text(
                                    member.initials,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: active
                                              ? Colors.white
                                              : const Color(0xFF151A19),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        member.relationship,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: active
                                              ? Colors.white60
                                              : const Color(0xFF777F7D),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: selected == null || saving
                          ? null
                          : () async {
                              setState(() => saving = true);
                              try {
                                await widget.onSelected(selected!);
                              } finally {
                                if (mounted) {
                                  setState(() => saving = false);
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF102A2C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        saving
                            ? 'Setting things up…'
                            : 'Continue as ${selected ?? 'yourself'}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'No account, PIN, or location tracking.',
                      style: TextStyle(
                        color: Color(0xFF838A88),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
