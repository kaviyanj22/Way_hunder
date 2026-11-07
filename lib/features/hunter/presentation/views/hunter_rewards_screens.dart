import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/hunter_models.dart';
import '../viewmodels/hunter_view_model.dart';
import 'hunter_ui.dart';

class HunterRewardsScreen extends ConsumerWidget {
  const HunterRewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hunterViewModelProvider);
    final vm = ref.read(hunterViewModelProvider.notifier);
    final approved = state.submissions
        .where((s) => s.status == HunterStatus.approved)
        .length;
    final pending = state.submissions
        .where((s) => s.status == HunterStatus.pending)
        .length;
    return HunterShell(
      title: 'Rewards & My Places',
      subtitle: 'UJ-013 · Hunter contributions and progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HunterPanel(
            child: Column(
              children: [
                const Icon(
                  Icons.workspace_premium_outlined,
                  color: hunterGold,
                  size: 64,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hunter Rewards',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
                ),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('Verified', '$approved', hunterGreen),
                    _stat('Pending', '$pending', hunterGold),
                    _stat(
                      'HP / Approval',
                      '+${state.seed.rewardHp}',
                      hunterGold,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Only approved places earn HP. This is a local demo reward simulation.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          HunterPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HunterSectionLabel(
                  'My Added Places',
                  icon: Icons.place_outlined,
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 0,
                  children: [
                    for (final tab in [
                      'All',
                      'Pending',
                      'Approved',
                      'Rejected',
                    ])
                      ChoiceChip(
                        label: Text(tab, style: const TextStyle(fontSize: 11)),
                        selected: state.rewardsTab == tab,
                        onSelected: (_) => vm.setRewardsTab(tab),
                        selectedColor: hunterGold,
                      ),
                  ],
                ),
                if (state.filteredSubmissions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      'No submissions in this filter.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                for (final submission in state.filteredSubmissions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: hunterGold.withValues(alpha: .18),
                      child: Icon(
                        submission.status == HunterStatus.approved
                            ? Icons.verified
                            : Icons.pending_actions,
                        color: hunterGold,
                      ),
                    ),
                    title: Text(submission.name),
                    subtitle: Text(
                      '${submission.district} · ${submission.status.label}',
                    ),
                    trailing: Text(
                      submission.status == HunterStatus.approved
                          ? '+${state.seed.rewardHp} HP'
                          : submission.status.label,
                      style: TextStyle(
                        color: submission.status == HunterStatus.approved
                            ? hunterGreen
                            : hunterGold,
                        fontSize: 11,
                      ),
                    ),
                    onTap: () {
                      vm.selectSubmission(submission.id);
                      context.push('/hunter/verification');
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          HunterPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HunterSectionLabel(
                  'Badges & Achievements',
                  icon: Icons.military_tech_outlined,
                ),
                const Wrap(
                  spacing: 12,
                  runSpacing: 9,
                  children: [
                    Chip(
                      avatar: Icon(Icons.explore_outlined, size: 18),
                      label: Text('Discoverer'),
                    ),
                    Chip(
                      avatar: Icon(Icons.flag_outlined, size: 18),
                      label: Text('Explorer'),
                    ),
                    Chip(
                      avatar: Icon(Icons.emoji_events_outlined, size: 18),
                      label: Text('Contributor'),
                    ),
                  ],
                ),
                const Text(
                  'Achievement labels are UI examples; server ranking is not connected.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          HunterAction(
            label: 'Top Location Hunters',
            icon: Icons.emoji_events_outlined,
            onPressed: () => context.push('/hunter/leaderboard'),
          ),
          const SizedBox(height: 8),
          HunterAction(
            label: 'Hunter Home',
            secondary: true,
            icon: Icons.home_outlined,
            onPressed: () => context.go('/hunter'),
          ),
        ],
      ),
    );
  }

  Widget _stat(String title, String value, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(title, style: const TextStyle(fontSize: 10)),
    ],
  );
}

class HunterLeaderboardScreen extends ConsumerWidget {
  const HunterLeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hunterViewModelProvider);
    final vm = ref.read(hunterViewModelProvider.notifier);
    final rankings = [...state.seed.rankings]
      ..sort((a, b) => a.rank.compareTo(b.rank));
    return HunterShell(
      selectedIndex: 2,
      title: 'Top Location Hunters',
      subtitle: 'UJ-014 · Leaderboard & badges',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HunterPanel(
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 70,
                  color: hunterGold,
                ),
                const SizedBox(height: 7),
                const Text(
                  'Location Hunter Leaderboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 0,
                  children: [
                    for (final filter in ['District', 'Monthly', 'All-Time'])
                      ChoiceChip(
                        label: Text(filter),
                        selectedColor: hunterGold,
                        selected: state.leaderboardFilter == filter,
                        onSelected: (_) => vm.setLeaderboardFilter(filter),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  'DEMO: ${state.leaderboardFilter} ranking sample · ${state.seed.district}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          HunterPanel(
            child: Column(
              children: [
                for (final player in rankings)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: hunterGold,
                      child: Text(
                        '${player.rank}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    title: Text(player.name),
                    trailing: Text(
                      '${player.hp} HP',
                      style: const TextStyle(
                        color: hunterGold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                if (rankings.isEmpty) const Text('No ranking entries yet'),
              ],
            ),
          ),
          const SizedBox(height: 9),
          HunterAction(
            label: 'My Places & Rewards',
            icon: Icons.workspace_premium_outlined,
            secondary: true,
            onPressed: () => context.push('/hunter/rewards'),
          ),
          const SizedBox(height: 8),
          HunterAction(
            label: 'Return to Hunter Home',
            icon: Icons.home_outlined,
            onPressed: () => context.go('/hunter'),
          ),
        ],
      ),
    );
  }
}

class HunterAdminDemoScreen extends ConsumerWidget {
  const HunterAdminDemoScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hunterViewModelProvider);
    final vm = ref.read(hunterViewModelProvider.notifier);
    final selected = state.selected;
    return HunterShell(
      title: 'Verification Decision',
      subtitle: 'H-ADM · Local developer demo, not the real Admin Portal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HunterPanel(
            child: Column(
              children: [
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 58,
                  color: hunterGold,
                ),
                const SizedBox(height: 8),
                Text(
                  selected?.name ?? 'No submission selected',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Status: ${selected?.status.label ?? 'Unavailable'}'),
                const SizedBox(height: 8),
                const Text(
                  'This screen simulates admin approval and rejection on the local device. It does not verify GPS, photo authenticity or 360 video.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          if (selected?.status == HunterStatus.pending) ...[
            HunterAction(
              label: 'Approve (DEMO) · +${state.seed.rewardHp} HP',
              icon: Icons.verified,
              green: true,
              onPressed: () async {
                if (!vm.moderate(HunterStatus.approved)) {
                  hunterMessage(
                    context,
                    ref.read(hunterViewModelProvider).error ??
                        'Cannot approve.',
                  );
                  return;
                }
                await hunterAlert(
                  context,
                  'DEMO: Approved',
                  'Approved discovery. HP credited once to the local wallet and Profile Hunt Places.',
                );
                if (context.mounted) context.go('/hunter/verification');
              },
            ),
            const SizedBox(height: 9),
            HunterAction(
              label: 'Reject (DEMO)',
              icon: Icons.cancel_outlined,
              secondary: true,
              onPressed: () async {
                if (!vm.moderate(HunterStatus.rejected)) {
                  hunterMessage(
                    context,
                    ref.read(hunterViewModelProvider).error ?? 'Cannot reject.',
                  );
                  return;
                }
                await hunterAlert(
                  context,
                  'DEMO: Rejected',
                  'Submission was rejected. No Hunter reward was credited.',
                );
                if (context.mounted) context.go('/hunter/verification');
              },
            ),
          ] else
            HunterAction(
              label: 'View Status',
              icon: Icons.fact_check_outlined,
              onPressed: () => context.go('/hunter/verification'),
            ),
          const SizedBox(height: 9),
          HunterAction(
            label: 'Back to Hunter Home',
            icon: Icons.home_outlined,
            secondary: true,
            onPressed: () => context.go('/hunter'),
          ),
        ],
      ),
    );
  }
}
