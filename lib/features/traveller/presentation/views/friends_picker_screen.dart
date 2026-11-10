import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/wayhunter_palette.dart';
import '../../../../core/widgets/scenic_background.dart';
import '../viewmodels/traveller_view_model.dart';

/// Friends picker for a draft trip. Only returns selected IDs to the caller.
/// This repository currently has local demo friends, not a live social API.
class TripFriendsPickerScreen extends ConsumerStatefulWidget {
  const TripFriendsPickerScreen({super.key, this.initialSelected = const []});

  final List<String> initialSelected;

  @override
  ConsumerState<TripFriendsPickerScreen> createState() =>
      _TripFriendsPickerScreenState();
}

class _TripFriendsPickerScreenState
    extends ConsumerState<TripFriendsPickerScreen> {
  static const _cyan = WayhunterPalette.travellerCyan;
  late final Set<String> _selected;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelected};
  }

  @override
  Widget build(BuildContext context) {
    final traveller = ref.watch(travellerViewModelProvider);
    final friends = traveller.catalog.members
        .where((member) => member.id != traveller.ownerId)
        .toList(growable: false);
    final visible = friends
        .where((member) => member.name.toLowerCase().contains(_search))
        .toList(growable: false);

    return ScenicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Add Friends to Trip'),
          leading: IconButton(
            tooltip: 'Cancel and return to Create Trip',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: _panelDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.groups_rounded, color: _cyan),
                          SizedBox(width: 8),
                          Text(
                            'Select Trip Friends',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose friends to include in this trip. '
                        'Press Add to Trip to return without submitting the trip.',
                        style: TextStyle(
                          color: Color(0xFFD1E8EE),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => setState(
                          () => _search = value.trim().toLowerCase(),
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, color: _cyan),
                          hintText: 'Search friends',
                          filled: true,
                          fillColor: const Color(0xAA061B2A),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _cyan),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'Available Friends',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selected.length} selected',
                      style: const TextStyle(color: _cyan),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Local demo friends — live followers/following require the Friends API.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFC5D6DE)),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Text(
                            friends.isEmpty
                                ? 'No friends available yet.'
                                : 'No matching friends.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            final friend = visible[index];
                            final picked = _selected.contains(friend.id);
                            final name = friend.name.trim();
                            final initials = name.isEmpty
                                ? '?'
                                : name
                                      .split(RegExp(r'\s+'))
                                      .take(2)
                                      .map((part) => part[0].toUpperCase())
                                      .join();
                            return Material(
                              color: const Color(0xDC082A3B),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: picked
                                      ? _cyan
                                      : const Color(0xFF27798A),
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: CheckboxListTile(
                                key: ValueKey('select-friend-${friend.id}'),
                                value: picked,
                                activeColor: _cyan,
                                checkColor: Colors.black,
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                secondary: CircleAvatar(
                                  backgroundColor: const Color(0xFF145B72),
                                  child: Text(
                                    initials,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  'User ID: ${friend.id}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selected.add(friend.id);
                                    } else {
                                      _selected.remove(friend.id);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    key: const ValueKey('add-selected-friends-to-trip'),
                    onPressed: () =>
                        context.pop<List<String>>(_selected.toList()),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF04B8C8),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.group_add_outlined),
                    label: Text(
                      'Add to Trip (${_selected.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _panelDecoration() => BoxDecoration(
    color: const Color(0xD9072637),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _cyan),
    boxShadow: [
      BoxShadow(color: _cyan.withValues(alpha: 0.15), blurRadius: 14),
    ],
  );
}
