import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../wallet/presentation/viewmodels/wallet_view_model.dart';
import '../viewmodels/game_view_model.dart';
import 'game_ui.dart';

/// Matches the original Game Zone composition: stats, Create / Play,
/// sponsored challenge, four shortcuts and active challenges. No map here.
class GameZoneScreen extends ConsumerWidget {
  const GameZoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(gameViewModelProvider);
    final wallet = ref.watch(walletViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;
    final featured = games.games
        .where((g) => !g.finished && g.creatorId != games.userId)
        .firstOrNull;
    return GameShell(
      title: '🏆 Game Zone',
      subtitle: 'Explore · Challenge · Win Rewards',
      fixed: true,
      child: LayoutBuilder(
        builder: (context, limits) => FittedBox(
          alignment: Alignment.topCenter,
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 380,
            height: 660,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GamePanel(
                  color: gameGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Score(
                        label: 'Hunter Points',
                        number: '${wallet.hp} HP',
                        icon: Icons.sports_esports,
                        color: gamePurple,
                      ),
                      Container(width: 1, height: 35, color: Colors.white38),
                      _Score(
                        label: 'Reward Coins',
                        number: '${wallet.rc} RC',
                        icon: Icons.monetization_on,
                        color: const Color(0xFFFFC640),
                      ),
                      Container(width: 1, height: 35, color: Colors.white38),
                      _Score(
                        label: 'Your Rank',
                        number:
                            '#${games.seed.rankings.firstOrNull?.rank ?? 1}',
                        icon: Icons.emoji_events,
                        color: const Color(0xFFFFC640),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                SizedBox(
                  height: 148,
                  child: Row(
                    children: [
                      Expanded(
                        child: _HeroAction(
                          title: 'Create Game',
                          subtitle: 'Create a real-world location challenge for travellers.',
                          color: const Color(0xFF9135EA),
                          icon: Icons.add_circle_outline,
                          onTap: () {
                            ref
                                .read(gameViewModelProvider.notifier)
                                .startCreate();
                            context.push('/game/create/setup');
                          },
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: _HeroAction(
                          title: 'Play Game',
                          subtitle: 'Join treasure hunts and win rewards!',
                          color: const Color(0xFF13B64F),
                          icon: Icons.sports_esports,
                          onTap: () => context.push('/game/play'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.push('/game/sponsored'),
                  child: Container(
                    height: 102,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFC760)),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xDA4B205F),
                          Color(0xDF122D45),
                          Color(0xDA6D4018),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC445),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '🔥 Sponsored Hunt',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                games.seed.sponsors.firstOrNull?.title ??
                                    'Sponsored Treasure Hunt',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Challenges and rewards · DEMO',
                                style: TextStyle(
                                  color: Color(0xFFE7E6EC),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.card_giftcard_rounded,
                          color: Color(0xFFFFC64F),
                          size: 55,
                        ),
                        const Icon(
                          Icons.arrow_circle_right_rounded,
                          color: Colors.white,
                          size: 29,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                SizedBox(
                  height: 80,
                  child: Row(
                    children: [
                      Expanded(
                        child: _Shortcut(
                          icon: Icons.emoji_events,
                          label: 'Leaderboard',
                          onTap: () => context.push('/game/leaderboard'),
                          color: const Color(0xFFFFD05D),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _Shortcut(
                          icon: Icons.redeem,
                          label: 'Rewards Store',
                          onTap: () => context.push('/game/rewards'),
                          color: gamePurple,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _Shortcut(
                          icon: Icons.layers_outlined,
                          label: 'My Games',
                          onTap: () => context.push('/game/my-games'),
                          color: gameCyan,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _Shortcut(
                          icon: Icons.help_outline,
                          label: 'How to Play',
                          onTap: () => context.push('/game/how-to-play'),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                Expanded(
                  child: GamePanel(
                    padding: const EdgeInsets.all(10),
                    color: gameCyan,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              color: gameGreen,
                              size: 22,
                            ),
                            const SizedBox(width: 4),
                            const Expanded(
                              child: Text(
                                'Active Challenges Near You',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/game/district'),
                              child: const Text(
                                'View All →',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: gameGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (featured == null) {
                                context.push('/game/district');
                              } else {
                                ref
                                    .read(gameViewModelProvider.notifier)
                                    .selectDistrict(featured.district);
                                ref
                                    .read(gameViewModelProvider.notifier)
                                    .selectGame(featured.id);
                                context.push('/game/accept');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xEFECF9FC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: Image.asset(
                                      'assets/images/backgrounds/home_background.png',
                                      width: 91,
                                      height: 69,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          featured?.title ??
                                              'Discover a challenge',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF051B2B),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        Text(
                                          featured?.district ??
                                              'Select district',
                                          style: const TextStyle(
                                            color: Color(0xFF23445B),
                                            fontSize: 11,
                                          ),
                                        ),
                                        const Text(
                                          'Tap to view clues',
                                          style: TextStyle(
                                            color: Color(0xFF37616B),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9D7ED),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '+${featured?.rewardHp ?? 0} HP\n+${featured?.rewardRc ?? 0} RC',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF741C47),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
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
                ),
                const SizedBox(height: 4),
                Text(
                  'Logged in: ${user?.name ?? 'Traveller'}   ·   Local Game DEMO',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({
    required this.label,
    required this.number,
    required this.icon,
    required this.color,
  });
  final String label, number;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 27),
      const SizedBox(width: 4),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            number,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.white70),
          ),
        ],
      ),
    ],
  );
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });
  final String title, subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(21),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70),
        borderRadius: BorderRadius.circular(21),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: .94),
            const Color(0xE9081429),
            color.withValues(alpha: .89),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: Colors.white),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
              const Icon(
                Icons.arrow_circle_right_rounded,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: GamePanel(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}
