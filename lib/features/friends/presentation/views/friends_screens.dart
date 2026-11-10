import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/scenic_background.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../traveller/presentation/viewmodels/traveller_view_model.dart';
import '../../domain/entities/friend.dart';
import '../viewmodels/friends_view_model.dart';

const _cyan = Color(0xFF00E5F5);
const _gold = Color(0xFFFFC642);
const _panel = Color(0xDC031F30);
const _line = Color(0xAA09CDE6);

/// Shared screen chrome: original Wayhunter mountain background, dark glass
/// panels and the same four-slot bottom layout. Leaderboard is intentionally
/// inactive here per the updated Friends UI decision.
class _FriendsFrame extends StatelessWidget {
  const _FriendsFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => ScenicBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 4,
        leading: IconButton(
          tooltip: 'Go back',
          icon: const Icon(Icons.arrow_back_ios_new, size: 19),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: const Column(
          children: [
            Text(
              'WAYHUNTER',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'TRAVELLER',
              style: TextStyle(fontSize: 9, letterSpacing: 2.3, color: _cyan),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 1, 15, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFFB5DAE4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          decoration: BoxDecoration(
            color: const Color(0xE7001729),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              _nav(context, Icons.home_outlined, 'Home', '/home'),
              _nav(context, Icons.hiking_outlined, 'Traveller', '/traveller'),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 7),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: Colors.white38,
                        size: 21,
                      ),
                      Text(
                        'Leaderboard',
                        style: TextStyle(fontSize: 9, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
              ),
              _nav(context, Icons.person_outline, 'Profile', '/profile'),
            ],
          ),
        ),
      ),
    ),
  );

  static Widget _nav(
    BuildContext context,
    IconData icon,
    String label,
    String path,
  ) => Expanded(
    child: InkWell(
      onTap: () => context.go(path),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: label == 'Profile' ? _cyan : Colors.white,
              size: 21,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: label == 'Profile' ? _cyan : Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color = _panel,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _line, width: 1),
      color: color,
      boxShadow: [
        BoxShadow(color: _cyan.withValues(alpha: .08), blurRadius: 12),
      ],
    ),
    padding: padding,
    child: child,
  );
}

Widget _filledButton(String text, VoidCallback? callback, {IconData? icon}) =>
    FilledButton.icon(
      onPressed: callback,
      style: FilledButton.styleFrom(
        backgroundColor: _cyan,
        foregroundColor: const Color(0xFF001A25),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      icon: Icon(icon ?? Icons.person_add_alt_1_outlined, size: 18),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend, this.trailing, this.onTap});
  final WayhunterFriend friend;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: _Glass(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: const Color(0xFF0C6073),
            child: Text(
              friend.name.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    friend.handle,
                    style: const TextStyle(
                      color: Color(0xFFA3D4DD),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${friend.mutualCount} mutual friends',
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
        ],
      ),
    ),
  );
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.onChanged,
    this.hint = 'Search by name or username…',
  });
  final ValueChanged<String> onChanged;
  final String hint;
  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12),
      prefixIcon: const Icon(Icons.search, color: _cyan, size: 20),
      isDense: true,
      filled: true,
      fillColor: const Color(0xE4032B3B),
      contentPadding: const EdgeInsets.symmetric(vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: _cyan),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: _line),
      ),
    ),
  );
}

class FriendsHubScreen extends ConsumerWidget {
  const FriendsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsViewModelProvider);
    return _FriendsFrame(
      title: 'Friends',
      subtitle: 'Follow · Connect · Travel together',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(15, 4, 15, 15),
        children: [
          GestureDetector(
            onTap: () => context.push('/friends/discover'),
            child: IgnorePointer(
              child: _SearchInput(
                onChanged: (_) {},
                hint: 'Search friends, followers or people…',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric(
                'Friends',
                friends.mutualFriendsCount,
                Icons.groups,
                () => context.push('/friends/following'),
              ),
              const SizedBox(width: 7),
              _metric(
                'Followers',
                friends.followers.length,
                Icons.people_outline,
                () => context.push('/friends/followers'),
              ),
              const SizedBox(width: 7),
              _metric(
                'Following',
                friends.following.length,
                Icons.person_add_outlined,
                () => context.push('/friends/following'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _hubAction(
            context,
            Icons.people_alt_outlined,
            'Discover Friends',
            'Find fellow travellers on Wayhunter',
            '/friends/discover',
          ),
          const SizedBox(height: 9),
          _hubAction(
            context,
            Icons.mark_email_unread_outlined,
            'Friend Requests',
            '${friends.received.length} incoming requests · ${friends.sent.length} sent',
            '/friends/requests',
          ),
          const SizedBox(height: 9),
          _Glass(
            child: InkWell(
              onTap: () => _showInviteSheet(context),
              child: const Row(
                children: [
                  Icon(Icons.ios_share, color: _cyan),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invite Friends',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Share the Wayhunter app with your friends',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: _cyan),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          _hubAction(
            context,
            Icons.contacts_outlined,
            'My Contacts',
            'View matching demo friends',
            '/friends/contacts',
          ),
          const SizedBox(height: 17),
          const Text(
            'Following',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _gold,
            ),
          ),
          const SizedBox(height: 8),
          for (final id in friends.following)
            if (findDemoFriend(id) case final friend?)
              _FriendTile(
                friend: friend,
                trailing: const Icon(Icons.check_circle_outline, color: _cyan),
              ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Demo social data on this device; real follow requests require the backend.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String title, int value, IconData icon, VoidCallback action) =>
      Expanded(
        child: InkWell(
          onTap: action,
          child: _Glass(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
            child: Column(
              children: [
                Icon(icon, color: _gold, size: 19),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: _gold,
                  ),
                ),
                Text(title, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      );

  Widget _hubAction(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String route,
  ) => _Glass(
    child: InkWell(
      onTap: () => context.push(route),
      child: Row(
        children: [
          Icon(icon, color: _cyan, size: 27),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _cyan),
        ],
      ),
    ),
  );

  void _showInviteSheet(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xD0000C17),
      builder: (_) => const _InviteFriendsDialog(),
    );
  }
}

// Matches the supplied Wayhunter "Invite Friends" reference: a centered
// cyan-glass modal, landscape banner, link/copy row and three sharing actions.
// The invitation URL is a UI/demo template until the actual backend endpoint
// and app/deep-link configuration are implemented.
class _InviteFriendsDialog extends ConsumerWidget {
  const _InviteFriendsDialog();

  static const _inviteBaseUrl = 'https://wayhunter.app/invite/';

  Future<void> _copyLink(BuildContext context, String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Demo invite link copied')));
  }

  Future<void> _share(BuildContext context, String channel, String link) async {
    final message =
        'Join me on Wayhunter! Explore, travel and hunt places together. $link';
    late final Uri target;
    if (channel == 'Gmail') {
      target = Uri.https('mail.google.com', '/mail/', {
        'view': 'cm',
        'fs': '1',
        'su': 'Join me on Wayhunter',
        'body': message,
      });
    } else if (channel == 'WhatsApp') {
      target = Uri.https('wa.me', '/', {'text': message});
    } else if (channel == 'SMS') {
      target = Uri.parse('sms:?body=${Uri.encodeComponent(message)}');
    } else {
      return;
    }
    try {
      final opened = await launchUrl(
        target,
        mode: LaunchMode.externalApplication,
      );
      if (!context.mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No app is available to share via $channel')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open $channel on this device')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authViewModelProvider).user?.id ?? 'demo-user';
    final link = '$_inviteBaseUrl${Uri.encodeComponent(userId)}';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 370),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _line, width: 1.3),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xF5093746), Color(0xF0031623)],
            ),
            boxShadow: [
              BoxShadow(color: _cyan.withValues(alpha: .2), blurRadius: 22),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(15, 11, 15, 17),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    key: const ValueKey('invite-close'),
                    tooltip: 'Close',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                const Center(
                  child: CircleAvatar(
                    radius: 23,
                    backgroundColor: Color(0xFF05495A),
                    child: Icon(Icons.share_outlined, color: _cyan, size: 26),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Invite Friends',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Share the Wayhunter app with your friends\nand explore together!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFD5EAF2), fontSize: 12),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 106,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          AppAssets.commonSoftBackground,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xEB00141D), Color(0x19001924)],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.terrain, size: 32, color: _cyan),
                              SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  'Join me on\nWayhunter!',
                                  style: TextStyle(
                                    fontSize: 17,
                                    height: 1.15,
                                    fontWeight: FontWeight.w900,
                                    color: _cyan,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                const Row(
                  children: [
                    Icon(Icons.link, color: _cyan, size: 17),
                    SizedBox(width: 6),
                    Text(
                      'Your Invite Link',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 42,
                  padding: const EdgeInsets.only(left: 11, right: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xE4002735),
                    border: Border.all(color: _line),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          link,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('invite-copy'),
                        tooltip: 'Copy invite link',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _copyLink(context, link),
                        icon: const Icon(Icons.copy_outlined, color: _cyan),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Demo link – invite backend/deep link not active yet.',
                  style: TextStyle(fontSize: 10, color: Color(0xFFFFD18B)),
                ),
                const SizedBox(height: 13),
                const Text(
                  'Share via',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InviteShareCard(
                      label: 'Gmail',
                      icon: Icons.mail_outline,
                      iconColor: const Color(0xFFF76867),
                      onTap: () => _share(context, 'Gmail', link),
                    ),
                    const SizedBox(width: 8),
                    _InviteShareCard(
                      label: 'WhatsApp',
                      icon: Icons.chat_bubble_outline,
                      iconColor: const Color(0xFF31E780),
                      onTap: () => _share(context, 'WhatsApp', link),
                    ),
                    const SizedBox(width: 8),
                    _InviteShareCard(
                      label: 'SMS',
                      icon: Icons.sms_outlined,
                      iconColor: const Color(0xFF56B9FF),
                      onTap: () => _share(context, 'SMS', link),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteShareCard extends StatelessWidget {
  const _InviteShareCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 73,
        decoration: BoxDecoration(
          color: const Color(0xDF052F3F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
          boxShadow: [
            BoxShadow(color: _cyan.withValues(alpha: .1), blurRadius: 8),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 29),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Users who follow the signed-in traveller (demo data in this patch).
class FollowersListScreen extends ConsumerStatefulWidget {
  const FollowersListScreen({super.key});
  @override
  ConsumerState<FollowersListScreen> createState() =>
      _FollowersListScreenState();
}

class _FollowersListScreenState extends ConsumerState<FollowersListScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsViewModelProvider);
    final vm = ref.read(friendsViewModelProvider.notifier);
    final users = demoWayhunterFriends.where(
      (p) =>
          friends.followers.contains(p.id) &&
          ('${p.name} ${p.handle}').toLowerCase().contains(query.toLowerCase()),
    );
    return _FriendsFrame(
      title: 'Followers',
      subtitle: 'People who follow you',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: _SearchInput(
              onChanged: (text) => setState(() => query = text),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                for (final p in users)
                  _FriendTile(
                    friend: p,
                    trailing: friends.following.contains(p.id)
                        ? const Icon(Icons.check_circle, color: _cyan)
                        : _filledButton('Follow', () => vm.request(p.id)),
                  ),
                if (friends.followers.isEmpty) const Text('No followers yet'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Users the signed-in traveller follows (demo data in this patch).
class FollowingListScreen extends ConsumerStatefulWidget {
  const FollowingListScreen({super.key});
  @override
  ConsumerState<FollowingListScreen> createState() =>
      _FollowingListScreenState();
}

class _FollowingListScreenState extends ConsumerState<FollowingListScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsViewModelProvider);
    final vm = ref.read(friendsViewModelProvider.notifier);
    final users = demoWayhunterFriends.where(
      (p) =>
          friends.following.contains(p.id) &&
          ('${p.name} ${p.handle}').toLowerCase().contains(query.toLowerCase()),
    );
    return _FriendsFrame(
      title: 'Following',
      subtitle: 'Travellers you follow',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: _SearchInput(
              onChanged: (text) => setState(() => query = text),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                for (final p in users)
                  _FriendTile(
                    friend: p,
                    trailing: OutlinedButton(
                      onPressed: () => vm.unfollow(p.id),
                      child: const Text(
                        'Following',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                if (friends.following.isEmpty)
                  const Text('Not following anyone yet'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiscoverFriendsScreen extends ConsumerStatefulWidget {
  const DiscoverFriendsScreen({super.key});
  @override
  ConsumerState<DiscoverFriendsScreen> createState() =>
      _DiscoverFriendsScreenState();
}

class _DiscoverFriendsScreenState extends ConsumerState<DiscoverFriendsScreen> {
  String search = '';
  int filter = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsViewModelProvider);
    final vm = ref.read(friendsViewModelProvider.notifier);
    final candidates = demoWayhunterFriends.where((p) {
      final match = '${p.name} ${p.handle} ${p.location}'
          .toLowerCase()
          .contains(search.toLowerCase());
      return match &&
          (filter == 0 ||
              (filter == 1
                  ? p.mutualCount >= 5
                  : !state.following.contains(p.id)));
    });
    return _FriendsFrame(
      title: 'Discover Friends',
      subtitle: 'Find fellow travellers on Wayhunter',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: _SearchInput(onChanged: (v) => setState(() => search = v)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(['All', 'Mutual', 'Suggested'][i]),
                    selected: filter == i,
                    onSelected: (_) => setState(() => filter = i),
                    selectedColor: _cyan,
                    labelStyle: TextStyle(
                      color: filter == i ? Colors.black : Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(15, 4, 15, 10),
              children: [
                for (final person in candidates)
                  _FriendTile(
                    friend: person,
                    trailing: SizedBox(
                      width: 106,
                      child: state.following.contains(person.id)
                          ? OutlinedButton(
                              onPressed: () => vm.unfollow(person.id),
                              child: const Text(
                                'Following',
                                style: TextStyle(fontSize: 10),
                              ),
                            )
                          : state.sent.contains(person.id)
                          ? OutlinedButton(
                              onPressed: () => vm.cancelSent(person.id),
                              child: const Text(
                                'Requested',
                                style: TextStyle(fontSize: 10),
                              ),
                            )
                          : state.received.contains(person.id)
                          ? _filledButton(
                              'Accept',
                              () => vm.accept(person.id),
                              icon: Icons.check,
                            )
                          : _filledButton(
                              'Add Friend',
                              () => vm.request(person.id),
                            ),
                    ),
                  ),
                const Text(
                  'Friend request actions are stored locally for this demo only.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});
  @override
  ConsumerState<FriendRequestsScreen> createState() =>
      _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  bool received = true;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsViewModelProvider);
    final vm = ref.read(friendsViewModelProvider.notifier);
    final ids = received ? state.received : state.sent;
    return _FriendsFrame(
      title: 'Friend Requests',
      subtitle: 'Manage incoming and outgoing requests',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 4, 15, 8),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text('Received (${state.received.length})'),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Sent (${state.sent.length})'),
                ),
              ],
              selected: {received},
              onSelectionChanged: (s) => setState(() => received = s.first),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(15),
              children: [
                if (ids.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('No requests')),
                  ),
                for (final id in ids)
                  if (findDemoFriend(id) case final person?)
                    _FriendTile(
                      friend: person,
                      trailing: received
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Accept',
                                  onPressed: () => vm.accept(id),
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: _cyan,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Decline',
                                  onPressed: () => vm.decline(id),
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    color: Color(0xFFFF7683),
                                  ),
                                ),
                              ],
                            )
                          : TextButton(
                              onPressed: () => vm.cancelSent(id),
                              child: const Text('Cancel'),
                            ),
                    ),
                const Text(
                  'Demo requests: backend notifications are not connected yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TripAddFriendsScreen extends ConsumerStatefulWidget {
  const TripAddFriendsScreen({super.key, this.initial = const []});
  final List<String> initial;
  @override
  ConsumerState<TripAddFriendsScreen> createState() =>
      _TripAddFriendsScreenState();
}

class _TripAddFriendsScreenState extends ConsumerState<TripAddFriendsScreen> {
  late Set<String> selected;
  String search = '';
  @override
  void initState() {
    super.initState();
    selected = {...widget.initial};
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsViewModelProvider);
    final draft = ref.watch(travellerViewModelProvider).draft;
    final eligible = demoWayhunterFriends.where(
      (p) =>
          friends.following.contains(p.id) &&
          '${p.name} ${p.handle}'.toLowerCase().contains(search.toLowerCase()),
    );
    String date(DateTime? value) => value == null
        ? 'Choose dates in Create Trip'
        : DateFormat('dd MMM yyyy').format(value);
    return _FriendsFrame(
      title: 'Add Friends to Trip',
      subtitle: 'Select friends to add to your trip',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 4, 15, 9),
            child: _Glass(
              child: Row(
                children: [
                  const Icon(Icons.landscape_outlined, color: _gold, size: 33),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.title.isEmpty ? 'Your New Trip' : draft.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${date(draft.startDate)} – ${date(draft.endDate)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: _SearchInput(
              hint: 'Search your friends…',
              onChanged: (s) => setState(() => search = s),
            ),
          ),
          const SizedBox(height: 9),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                for (final person in eligible)
                  _FriendTile(
                    friend: person,
                    onTap: () => setState(
                      () => selected.contains(person.id)
                          ? selected.remove(person.id)
                          : selected.add(person.id),
                    ),
                    trailing: Checkbox(
                      value: selected.contains(person.id),
                      activeColor: _cyan,
                      checkColor: Colors.black,
                      onChanged: (v) => setState(
                        () => v == true
                            ? selected.add(person.id)
                            : selected.remove(person.id),
                      ),
                    ),
                  ),
                if (friends.following.isEmpty)
                  const Center(
                    child: Text(
                      'No following friends yet. Open Profile → Friends to connect.',
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 7, 15, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Glass(
                  child: Row(
                    children: [
                      const Icon(Icons.groups_2_outlined, color: _cyan),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '${selected.length} friends selected',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.check, color: _cyan),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                _filledButton(
                  'Add to Trip (${selected.length})',
                  () => context.canPop()
                      ? context.pop(selected.toList())
                      : context.go('/traveller/create'),
                  icon: Icons.send_outlined,
                ),
                const SizedBox(height: 5),
                const Text(
                  'Only selected friend IDs return to Create Trip. This does NOT submit the trip or send live invites.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MyContactsDemoScreen extends ConsumerWidget {
  const MyContactsDemoScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsViewModelProvider);
    final vm = ref.read(friendsViewModelProvider.notifier);
    return _FriendsFrame(
      title: 'My Contacts',
      subtitle: 'Demo Wayhunter members · no phonebook access',
      child: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          const _Glass(
            child: Text(
              'For privacy, this prototype does not read device contacts. Real contact matching needs user consent and a backend matching API.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          for (final person in demoWayhunterFriends.take(6))
            _FriendTile(
              friend: person,
              trailing: stateButton(friends, person.id, vm),
            ),
        ],
      ),
    );
  }

  Widget stateButton(FriendsState friends, String id, FriendsViewModel vm) =>
      friends.following.contains(id)
      ? const Icon(Icons.check, color: _cyan)
      : friends.sent.contains(id)
      ? const Text('Requested', style: TextStyle(color: _gold, fontSize: 11))
      : _filledButton('Follow', () => vm.request(id));
}
