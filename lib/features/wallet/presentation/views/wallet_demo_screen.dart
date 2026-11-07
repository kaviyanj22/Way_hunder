import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/wallet_view_model.dart';
import 'wallet_ui.dart';

class WalletDemoScreen extends ConsumerStatefulWidget {
  const WalletDemoScreen({super.key, this.code});
  final String? code;
  @override
  ConsumerState<WalletDemoScreen> createState() => _WalletDemoScreenState();
}

class _WalletDemoScreenState extends ConsumerState<WalletDemoScreen> {
  late final _code = TextEditingController(text: widget.code ?? '');
  late String _tab = widget.code == null ? 'Requests' : 'Merchant';
  final _busy = <String>{};
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletViewModelProvider);
    final vm = ref.read(walletViewModelProvider.notifier);
    if (!ref.watch(walletDemoToolsEnabledProvider)) {
      return WalletShell(
        title: 'DEMO tools disabled',
        child: WalletEmpty(
          message: 'Developer controls are unavailable in this build.',
          label: 'Back to Wallet',
          onPressed: () => context.go('/wallet'),
        ),
      );
    }
    return WalletShell(
      title: 'DEMO Testing Area',
      subtitle: 'Local simulation • no real admin or merchant',
      child: Column(
        children: [
          const WalletGlass(
            accent: walletPurple,
            padding: EdgeInsets.all(10),
            child: Text(
              'DEBUG ONLY • NOT A REAL ADMIN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: walletPurple,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
          WalletTabs(
            labels: const ['Requests', 'Merchant'],
            selected: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _tab == 'Requests'
                ? state.requests.isEmpty
                      ? WalletEmpty(
                          message: 'No requests to test.',
                          label: 'Choose a voucher',
                          onPressed: () => context.push('/wallet/choose'),
                        )
                      : ListView.separated(
                          itemCount: state.requests.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final request = state.requests.reversed.elementAt(
                              i,
                            );
                            final offer = state.offerById(request.offerId)!;
                            return WalletGlass(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  WalletOfferSummary(offer: offer),
                                  const SizedBox(height: 8),
                                  Text(
                                    request.id,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  const SizedBox(height: 8),
                                  WalletPill(
                                    request.status.name[0].toUpperCase() +
                                        request.status.name.substring(1),
                                  ),
                                  const SizedBox(height: 10),
                                  if (request.status == RequestStatus.pending)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: WalletButton(
                                            key: ValueKey(
                                              'wallet-demo-approve-${request.id}',
                                            ),
                                            label: 'DEMO approve',
                                            onPressed:
                                                _busy.contains(request.id)
                                                ? null
                                                : () async {
                                                    setState(
                                                      () =>
                                                          _busy.add(request.id),
                                                    );
                                                    final success = vm.approve(
                                                      request.id,
                                                    );
                                                    await vm.persistenceSettled;
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    setState(
                                                      () => _busy.remove(
                                                        request.id,
                                                      ),
                                                    );
                                                    if (success) {
                                                      context.push(
                                                        walletRequestPath(
                                                          '/wallet/approved',
                                                          request.id,
                                                        ),
                                                      );
                                                    } else {
                                                      walletFeedback(
                                                        context,
                                                        ref
                                                                .read(
                                                                  walletViewModelProvider,
                                                                )
                                                                .error ??
                                                            'Demo approval unavailable.',
                                                      );
                                                    }
                                                  },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: WalletButton(
                                            key: ValueKey(
                                              'wallet-demo-reject-${request.id}',
                                            ),
                                            label: 'DEMO reject',
                                            outline: true,
                                            onPressed:
                                                _busy.contains(request.id)
                                                ? null
                                                : () async {
                                                    setState(
                                                      () =>
                                                          _busy.add(request.id),
                                                    );
                                                    final success = vm.reject(
                                                      request.id,
                                                    );
                                                    await vm.persistenceSettled;
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    setState(
                                                      () => _busy.remove(
                                                        request.id,
                                                      ),
                                                    );
                                                    if (success) {
                                                      context.push(
                                                        walletRequestPath(
                                                          '/wallet/rejected',
                                                          request.id,
                                                        ),
                                                      );
                                                    } else {
                                                      walletFeedback(
                                                        context,
                                                        ref
                                                                .read(
                                                                  walletViewModelProvider,
                                                                )
                                                                .error ??
                                                            'Demo rejection unavailable.',
                                                      );
                                                    }
                                                  },
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    WalletButton(
                                      label: 'View decision',
                                      outline: true,
                                      onPressed: () => context.push(
                                        vm.routeForRequest(request),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        )
                : _MerchantForm(
                    code: _code,
                    onUse: () async {
                      FocusScope.of(context).unfocus();
                      final success = vm.useVoucherCode(_code.text);
                      await vm.persistenceSettled;
                      if (!context.mounted) return;
                      walletFeedback(
                        context,
                        success
                            ? 'Voucher marked used in this local DEMO. No merchant was contacted.'
                            : ref.read(walletViewModelProvider).error ??
                                  'Invalid demo code.',
                      );
                    },
                    error: state.error,
                    voucherId: state.selectedVoucherId,
                  ),
          ),
        ],
      ),
    );
  }
}

class _MerchantForm extends StatelessWidget {
  const _MerchantForm({
    required this.code,
    required this.onUse,
    required this.error,
    required this.voucherId,
  });
  final TextEditingController code;
  final VoidCallback onUse;
  final String? error, voucherId;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limits) => SingleChildScrollView(
      child: WalletGlass(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DEMO merchant redemption',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              'Use a demo code or demo QR identifier. This does not redeem a real voucher.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('wallet-merchant-code'),
              controller: code,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Demo voucher code'),
            ),
            const SizedBox(height: 14),
            WalletButton(
              key: const ValueKey('wallet-merchant-use'),
              label: 'DEMO mark as used',
              onPressed: onUse,
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error!,
                  style: const TextStyle(
                    color: Color(0xFFFF8E96),
                    fontSize: 12,
                  ),
                ),
              ),
            if (voucherId != null) ...[
              const SizedBox(height: 10),
              WalletButton(
                label: 'View voucher record',
                outline: true,
                onPressed: () => context.push(
                  walletRequestPath('/wallet/voucher', voucherId!),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
