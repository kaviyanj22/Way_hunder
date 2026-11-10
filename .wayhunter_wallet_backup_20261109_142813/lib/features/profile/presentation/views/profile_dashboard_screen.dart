import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/wayhunter_palette.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/scenic_background.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../games/presentation/viewmodels/game_view_model.dart';
import '../../../hunter/domain/hunter_models.dart';
import '../../../hunter/presentation/viewmodels/hunter_view_model.dart';
import '../../../traveller/presentation/viewmodels/traveller_view_model.dart';
import '../../../wallet/presentation/viewmodels/wallet_view_model.dart';
import '../viewmodels/profile_view_model.dart';

const _cyan = WayhunterPalette.travellerCyan;

/// Profile view based on the approved five-tab visual reference. Its Posts and
/// Trips are read from the SAME Traveller provider as the active journey.
class ProfileDashboardScreen extends ConsumerStatefulWidget {
  const ProfileDashboardScreen({super.key});

  @override
  ConsumerState<ProfileDashboardScreen> createState() =>
      _ProfileDashboardScreenState();
}

class _ProfileDashboardScreenState
    extends ConsumerState<ProfileDashboardScreen> {
  int tab = 1; // The reference opens with Posts selected.
  static const tabs = [
    (Icons.sports_esports_outlined, 'Games'),
    (Icons.photo_library_outlined, 'Posts'),
    (Icons.map_outlined, 'Trips'),
    (Icons.place_outlined, 'Hunt Places'),
    (Icons.account_balance_wallet_outlined, 'My Wallet'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).user;
    final details = ref.watch(profileDetailsProvider);
    final wallet = ref.watch(walletViewModelProvider);
    if (user == null) {
      return Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/sign-in'),
            child: const Text('Sign In'),
          ),
        ),
      );
    }
    return ScenicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 0, 13, 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: NavigationBar(
                height: 60,
                backgroundColor: const Color(0xD9001C2D),
                selectedIndex: 3,
                indicatorColor: _cyan.withValues(alpha: .25),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.hiking),
                    label: 'Traveller',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.emoji_events_outlined),
                    label: 'Leaderboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
                onDestinationSelected: (i) => context.go(switch (i) {
                  0 => '/home',
                  1 => '/traveller',
                  2 => '/leaderboard',
                  _ => '/profile',
                }),
              ),
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 0, 9, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 53,
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Back to Home',
                            onPressed: () => context.go('/home'),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'WAYHUNTER',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  'PROFILE',
                                  style: TextStyle(
                                    color: _cyan,
                                    letterSpacing: 2,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Notifications',
                            onPressed: () => context.go('/notifications'),
                            icon: const Icon(Icons.notifications_outlined),
                          ),
                          IconButton(
                            tooltip: 'Settings',
                            onPressed: () => context.go('/profile/settings'),
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ],
                      ),
                    ),
                    _identity(
                      context,
                      user.name,
                      details.bio,
                      details.location,
                      user.avatarBytes,
                      wallet.hp,
                    ),
                    // Open the shared Friends hub from Profile (not the active-trip friends page).
                    const SizedBox(height: 5),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        key: const ValueKey('profile-friends-entry'),
                        onPressed: () => context.push('/friends'),
                        icon: const Icon(Icons.people_alt_outlined, size: 18),
                        label: const Text('Friends'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _cyan,
                          backgroundColor: const Color(0xD5032837),
                          side: const BorderSide(color: _cyan),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.workspace_premium,
                            color: Color(0xFFFFC857),
                            size: 34,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Travel Explorer · Level ${user.level}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: (wallet.hp % 5000) / 5000,
                                  color: _cyan,
                                  backgroundColor: const Color(0xFF16485C),
                                  minHeight: 7,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('My Badges'),
                                content: const Text(
                                  'Travel Explorer · Trail Starter · Local Discoverer (demo badges)',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            ),
                            child: const Text(
                              'My Badges',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < tabs.length; i++)
                            Expanded(
                              child: InkWell(
                                key: ValueKey('profile-tab-$i'),
                                onTap: () {
                                  if (i == 4) {
                                    // My Wallet is a separate screen, never a profile dropdown.
                                    context.push('/wallet');
                                  } else {
                                    setState(() => tab = i);
                                  }
                                },
                                borderRadius: BorderRadius.circular(13),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: tab == i
                                        ? const Border(
                                            bottom: BorderSide(
                                              color: _cyan,
                                              width: 2.5,
                                            ),
                                          )
                                        : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        tabs[i].$1,
                                        color: tab == i ? _cyan : Colors.white,
                                        size: 22,
                                      ),
                                      const SizedBox(height: 2),
                                      FittedBox(
                                        child: Text(
                                          tabs[i].$2,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: tab == i
                                                ? _cyan
                                                : Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: _tabContent()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _identity(
    BuildContext context,
    String name,
    String bio,
    String location,
    Uint8List? avatar,
    int hp,
  ) => GlassPanel(
    padding: const EdgeInsets.all(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => context.go('/profile/edit'),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF075C76),
            backgroundImage: avatar == null ? null : MemoryImage(avatar),
            child: avatar == null ? const Icon(Icons.person, size: 40) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
              Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF98E8F8)),
              ),
              Text(
                '$hp HP · Local traveller',
                style: const TextStyle(fontSize: 10),
              ),
              TextButton.icon(
                onPressed: () => context.go('/profile/edit'),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 11),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _tabContent() => switch (tab) {
    0 => _gamesTab(),
    1 => _postsTab(),
    2 => _tripsTab(),
    3 => _hunterTab(),
    _ => _postsTab(),
  };

  Widget _gamesTab() {
    final state = ref.watch(gameViewModelProvider);
    final games = [...state.createdGames, ...state.joinedGames];
    return _itemsList(games.isEmpty ? 'No games yet' : null, [
      for (final game in games)
        _listCard(
          game.title,
          '${game.district} · ${game.finished ? 'Completed' : 'Available'}',
          Icons.sports_esports_outlined,
          () => context.go('/game'),
        ),
    ]);
  }

  Widget _postsTab() {
    final traveller = ref.watch(travellerViewModelProvider);
    final memories = traveller.memories;
    if (memories.isEmpty) {
      return _empty(
        'No travel memories yet',
        'Open an active trip → Add Memories → Post. Your posts will appear here.',
      );
    }
    return GridView.builder(
      key: const ValueKey('profile-posts-grid'),
      padding: const EdgeInsets.only(bottom: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 7,
        mainAxisSpacing: 7,
        childAspectRatio: .92,
      ),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final memory = memories[memories.length - index - 1];
        return InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(memory.stop),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 180, child: _memoryImage(memory)),
                    const SizedBox(height: 8),
                    Text(memory.caption),
                    Text(
                      memory.tags.join(' · '),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _memoryImage(memory),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: const Color(0xB5001024),
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      memory.stop,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _memoryImage(TripMemory memory) {
    final photo = memory.evidence.where((e) => !e.video).firstOrNull;
    if (photo?.bytes != null) {
      return Image.memory(photo!.bytes!, fit: BoxFit.cover);
    }
    if (photo?.path != null) {
      return Image.file(
        File(photo!.path!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _PostPlaceholder(),
      );
    }
    return const _PostPlaceholder();
  }

  Widget _tripsTab() {
    final state = ref.watch(travellerViewModelProvider);
    final plans = state.plans.where((p) => p.ownerId == state.ownerId).toList();
    return _itemsList(plans.isEmpty ? 'No saved trips' : null, [
      for (final p in plans.reversed)
        _listCard(
          p.title,
          '${p.stops.join(' → ')}\n${p.status.name.toUpperCase()} · ${p.days} days',
          Icons.route,
          () => context.go(
            p.status == TripStatus.completed
                ? '/traveller/finish?id=${Uri.encodeComponent(p.id)}'
                : '/traveller/plans',
          ),
        ),
    ]);
  }

  Widget _hunterTab() {
    final state = ref.watch(hunterViewModelProvider);
    final approved = state.submissions
        .where(
          (s) => s.userId == state.userId && s.status == HunterStatus.approved,
        )
        .toList();
    return _itemsList(approved.isEmpty ? 'No verified discoveries yet' : null, [
      for (final item in approved)
        _listCard(
          item.name,
          '${item.district} · Verified discovery',
          Icons.explore_outlined,
          () => context.go('/hunter'),
        ),
    ]);
  }

  Widget _itemsList(String? empty, List<Widget> rows) {
    if (empty != null) {
      return _empty(empty, 'New activity appears here when you save it.');
    }
    return ListView(padding: const EdgeInsets.only(bottom: 16), children: rows);
  }

  Widget _listCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: GlassPanel(
      padding: const EdgeInsets.all(9),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: _cyan),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    ),
  );

  Widget _empty(String title, String message) => Center(
    child: GlassPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_library_outlined, color: _cyan, size: 32),
          const SizedBox(height: 9),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _PostPlaceholder extends StatelessWidget {
  const _PostPlaceholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFF06435B),
    child: Center(
      child: Icon(Icons.photo_camera_outlined, color: Colors.white70, size: 40),
    ),
  );
}

class EditLocalProfileScreen extends ConsumerStatefulWidget {
  const EditLocalProfileScreen({super.key});
  @override
  ConsumerState<EditLocalProfileScreen> createState() =>
      _EditLocalProfileScreenState();
}

class _EditLocalProfileScreenState
    extends ConsumerState<EditLocalProfileScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _location = TextEditingController();
  Uint8List? _photo;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    try {
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 450,
        imageQuality: 65,
      );
      if (selected != null && mounted) {
        final bytes = await selected.readAsBytes();
        if (bytes.lengthInBytes > 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Choose an image smaller than 1 MB for local profile saving.',
                ),
              ),
            );
          }
          return;
        }
        if (mounted) setState(() => _photo = bytes);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gallery access unavailable on this device.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).user;
    final prefs = ref.watch(profileDetailsProvider);
    if (!_initialized) {
      _name.text = user?.name ?? '';
      _bio.text = prefs.bio;
      _location.text = prefs.location;
      _initialized = true;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 45,
                backgroundImage: _photo != null
                    ? MemoryImage(_photo!)
                    : user?.avatarBytes == null
                    ? null
                    : MemoryImage(user!.avatarBytes!),
                child: (_photo ?? user?.avatarBytes) == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
            ),
            TextButton.icon(
              onPressed: _choosePhoto,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Change Photo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              maxLength: 50,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            TextField(
              controller: _bio,
              maxLength: 140,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            TextField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      if (_name.text.trim().length < 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Enter at least two characters for your name.',
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() => _saving = true);
                      await ref
                          .read(authViewModelProvider.notifier)
                          .saveDemoProfile(
                            name: _name.text.trim(),
                            avatarBytes: _photo,
                          );
                      await ref
                          .read(profileDetailsProvider.notifier)
                          .update(
                            bio: _bio.text.trim(),
                            location: _location.text.trim(),
                          );
                      if (mounted) context.go('/profile');
                    },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Changes Locally'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(profileDetailsProvider);
    final vm = ref.read(profileDetailsProvider.notifier);
    return ScenicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _setting(
                context,
                'Security & Password',
                Icons.lock_outline,
                () => _info(
                  context,
                  'Security & Password',
                  'This offline demo does not have a secure server password-change endpoint. Use the existing Forgot Password flow when signed out.',
                ),
              ),
              _setting(
                context,
                'Language: ${prefs.language}',
                Icons.language,
                () => showDialog<void>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: const Text('Language'),
                    children: [
                      for (final language in ['Tamil', 'Sinhala', 'English'])
                        SimpleDialogOption(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await vm.update(language: language);
                          },
                          child: Text(language),
                        ),
                    ],
                  ),
                ),
              ),
              _setting(
                context,
                'Privacy: ${prefs.publicProfile ? 'Public' : 'Private'}',
                Icons.visibility_outlined,
                () => showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Privacy'),
                    content: const Text(
                      'Change your local demo profile visibility.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await vm.update(publicProfile: false);
                        },
                        child: const Text('Private'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await vm.update(publicProfile: true);
                        },
                        child: const Text('Public'),
                      ),
                    ],
                  ),
                ),
              ),
              _setting(
                context,
                'Notifications',
                Icons.notifications_outlined,
                () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const _NotificationSettingsSheet(),
                ),
              ),
              _setting(
                context,
                'Help & Support',
                Icons.help_outline,
                () => _info(
                  context,
                  'How to Use Wayhunter',
                  'Traveller: Create Trip → My Plans → Start Trip → Nearby / Hazard / Memories / Friends → Finish. Hunter and Game use local demo state.',
                ),
              ),
              _setting(
                context,
                'About Wayhunter',
                Icons.info_outline,
                () => _info(
                  context,
                  'About Wayhunter',
                  'Wayhunter local UI prototype · version 1.0.0. Google Maps may display live tiles; contributions and vouchers are simulations.',
                ),
              ),
              _setting(
                context,
                'Delete Account',
                Icons.delete_outline,
                () => _info(
                  context,
                  'Account Deletion',
                  'Account deletion requires a real backend. This offline prototype cannot claim that a real account was deleted.',
                ),
              ),
              _setting(
                context,
                'Logout',
                Icons.logout,
                () => showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Log out of Wayhunter?'),
                    content: const Text(
                      'Your locally saved trip activity stays on this device.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(authViewModelProvider.notifier).signOut();
                          context.go('/sign-in');
                        },
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _setting(
    BuildContext ctx,
    String title,
    IconData icon,
    VoidCallback action,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: GlassPanel(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: _cyan),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: action,
      ),
    ),
  );

  void _info(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingsSheet extends ConsumerWidget {
  const _NotificationSettingsSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(profileDetailsProvider);
    final vm = ref.read(profileDetailsProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Notification Preferences',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            for (final entry in prefs.notifications.entries)
              SwitchListTile(
                title: Text(entry.key),
                value: entry.value,
                onChanged: (value) => vm.update(
                  notifications: {...prefs.notifications, entry.key: value},
                ),
              ),
            const Text(
              'These switches affect local demo preferences; no push service is connected.',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
