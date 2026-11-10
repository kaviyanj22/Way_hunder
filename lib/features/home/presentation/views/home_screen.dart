import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/home_profile_bottom_nav.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../viewmodels/home_view_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    final home = ref.watch(homeViewModelProvider);
    // Leave room for the WAYHUNTER logo baked into the background image.
    // This scales with the screen so small phones don't get a huge empty gap.
    final logoSpace = (MediaQuery.sizeOf(context).height * 0.09)
        .clamp(58.0, 82.0).toDouble();

    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/images/backgrounds/wayhunter_auth_home_bg.png',
          ),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: const HomeProfileBottomNav(),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Open Profile',
                            onPressed: () => context.push('/profile'),
                            icon: CircleAvatar(
                              radius: 16,
                              backgroundImage: user?.avatarBytes == null
                                  ? null
                                  : MemoryImage(user!.avatarBytes!),
                              child: user?.avatarBytes == null
                                  ? const Icon(Icons.person_outline, size: 24)
                                  : null,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, ${user?.name ?? ''}',
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const Text(
                                  'Ready for a new adventure?',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFD3E1EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Search places',
                            onPressed: () {
                              ref
                                  .read(homeViewModelProvider.notifier)
                                  .search('');
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const _SearchSheet(),
                              );
                            },
                            icon: const Icon(Icons.search),
                          ),
                          Badge(
                            isLabelVisible: home.unreadCount > 0,
                            label: Text('${home.unreadCount}'),
                            child: IconButton(
                              tooltip: 'Notifications',
                              onPressed: () => context.push('/notifications'),
                              icon: const Icon(Icons.notifications_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: logoSpace),
                    if (home.content.advertisements.isNotEmpty)
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                              home.content.advertisements.first.title,
                            ),
                            content: Text(
                              '${home.content.advertisements.first.description}.\n\nDEMO advertisement. No booking, payment or sponsor service is connected.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        ),
                        child: GlassPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 19,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'ADVERTISEMENT · DEMO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 1.6,
                                        color: Color(0xFF8FDDFF),
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      home.content.advertisements.first.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    Text(
                                      home
                                          .content
                                          .advertisements
                                          .first
                                          .description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.storefront_outlined, size: 32),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 7),
                    const _ModeButton(
                      asset: 'assets/images/buttons/traveler_button.png',
                      label: 'Open Traveller',
                      route: '/traveller',
                    ),
                    // No extra vertical space between the three cards.
                    const _ModeButton(
                      asset: 'assets/images/buttons/hunter_button.png',
                      label: 'Open Hunter',
                      route: '/hunter',
                    ),
                    const _ModeButton(
                      asset: 'assets/images/buttons/game_button.png',
                      label: 'Open Game',
                      route: '/game',
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'LOCAL DEMO  ·  Phase 1 prototype',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: Color(0xFFE6F1F8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.asset,
    required this.label,
    required this.route,
  });
  final String asset;
  final String label;
  final String route;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    image: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(route),
        // Original PNGs have transparent margins. A more compact card
        // crops only the very top/bottom margins without stretching text.
        child: AspectRatio(
          aspectRatio: 3.65,
          child: ClipRect(
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              width: double.infinity,
              excludeFromSemantics: true,
              errorBuilder: (_, error, stackTrace) => Center(
                child: Text('Image not found: $asset'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SearchSheet extends ConsumerWidget {
  const _SearchSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          0,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .58,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Find a little inspiration',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Search the local demo places. No live Places service.',
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                onChanged: ref.read(homeViewModelProvider.notifier).search,
                decoration: const InputDecoration(
                  labelText: 'Search by place or district',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: state.searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          'No demo places match. Try another search.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.searchResults.length,
                        itemBuilder: (context, index) {
                          final place = state.searchResults[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.place_outlined),
                            title: Text(place.name),
                            subtitle: Text(
                              '${place.district} · ${place.category}',
                            ),
                            trailing: const Icon(Icons.arrow_forward_rounded),
                            onTap: () {
                              Navigator.pop(context);
                              context.push(
                                '/traveller?place=${Uri.encodeComponent(place.id)}',
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
