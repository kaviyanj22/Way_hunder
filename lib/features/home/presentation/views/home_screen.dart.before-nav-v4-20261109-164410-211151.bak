import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/scenic_background.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../viewmodels/home_view_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    final home = ref.watch(homeViewModelProvider);
    return ScenicBackground(
      dim: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: const AppNavBar(),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                    const SizedBox(height: 165),
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
                          padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 18),
                    const _ModeButton(
                      asset: AppAssets.travellerButton,
                      label: 'Open Traveller',
                      route: '/traveller',
                    ),
                    const SizedBox(height: 14),
                    const _ModeButton(
                      asset: AppAssets.hunterButton,
                      label: 'Open Hunter',
                      route: '/hunter',
                    ),
                    const SizedBox(height: 14),
                    const _ModeButton(
                      asset: AppAssets.gameButton,
                      label: 'Open Game',
                      route: '/game',
                    ),
                    const SizedBox(height: 18),
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
        child: AspectRatio(
          aspectRatio: 3.8,
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            width: double.infinity,
            excludeFromSemantics: true,
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
