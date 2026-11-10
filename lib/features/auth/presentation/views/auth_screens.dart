import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/device_permission_service.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../../../core/widgets/scenic_background.dart';
import '../../domain/auth_repository.dart';
import '../viewmodels/auth_view_model.dart';

Future<void> _navigate(BuildContext context, Future<String?> action) async {
  final route = await action;
  if (context.mounted && route != null) context.go(route);
}

class _AuthLayout extends StatelessWidget {
  const _AuthLayout({
    required this.title,
    required this.child,
    this.subtitle,
    this.header,
    this.backRoute,
    this.onBack,
    this.fixedRegister = false,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? header;
  final String? backRoute;
  final VoidCallback? onBack;

  /// Main Register page is not scrollable when the keyboard is closed.
  /// Keyboard-open form input remains scrollable for accessibility.
  final bool fixedRegister;

  Widget _content(BuildContext context, double topGap) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (backRoute != null)
                IconButton.filledTonal(
                  tooltip: 'Go back',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: onBack ?? () => context.go(backRoute!),
                )
              else
                const Icon(Icons.explore_outlined, color: Color(0xFF35E9ED)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'WAYHUNTER',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
              ),
              ?header,
            ],
          ),
          SizedBox(height: topGap),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 10),
                  Text(subtitle!, textAlign: TextAlign.center),
                ],
                SizedBox(height: fixedRegister ? 10 : 24),
                child,
              ],
            ),
          ),
          SizedBox(height: fixedRegister ? 5 : 14),
          const Text(
            'LOCAL DEMO  •  No live authentication',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 6, color: Colors.black)],
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: backRoute == null,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && backRoute != null) {
        if (onBack != null) {
          onBack!();
        } else {
          context.go(backRoute!);
        }
      }
    },
    child: ScenicBackground(
      dim: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
              if (fixedRegister) {
                final formWidth = (constraints.maxWidth - 28)
                    .clamp(300.0, 410.0)
                    .toDouble();
                // Keep the same input subtree mounted while the keyboard opens:
                // rebuilding it under a different parent would lose focus.
                final fullHeight =
                    constraints.maxHeight +
                    MediaQuery.viewInsetsOf(context).bottom;
                return SingleChildScrollView(
                  physics: keyboardOpen
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    height: fullHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: formWidth,
                          child: _content(context, 8),
                        ),
                      ),
                    ),
                  ),
                );
              }
              // The keyboard-open layout deliberately allows form-field access.
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  22,
                  fixedRegister ? 7 : 12,
                  22,
                  fixedRegister ? 12 : 28,
                ),
                child: _content(
                  context,
                  fixedRegister
                      ? 8.0
                      : (constraints.maxHeight * .22)
                            .clamp(76.0, 190.0)
                            .toDouble(),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _AuthField extends StatefulWidget {
  const _AuthField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.icon,
    this.secret = false,
    this.keyboard,
    this.validator,
    this.fieldKey,
    this.maxLength,
    this.formatters,
    this.autofillHints,
    this.compact = false,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final bool secret;
  final bool compact;
  final TextInputType? keyboard;
  final FormFieldValidator<String>? validator;
  final Key? fieldKey;
  final int? maxLength;
  final List<TextInputFormatter>? formatters;
  final Iterable<String>? autofillHints;
  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  bool _visible = false;
  @override
  void didUpdateWidget(covariant _AuthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      final expected = widget.value;
      // Form controllers notify their FormField. Synchronize external updates
      // (demo fill, remembered email, sign-out) after this build has completed.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            widget.value != expected ||
            _controller.text == expected) {
          return;
        }
        _controller.value = TextEditingValue(
          text: expected,
          selection: TextSelection.collapsed(offset: expected.length),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: widget.compact ? 5 : 14),
    child: TextFormField(
      key: widget.fieldKey,
      controller: _controller,
      onChanged: widget.onChanged,
      validator: widget.validator,
      obscureText: widget.secret && !_visible,
      enableSuggestions: !widget.secret,
      autocorrect: !widget.secret,
      keyboardType: widget.keyboard,
      maxLength: widget.maxLength,
      inputFormatters: widget.formatters,
      autofillHints: widget.autofillHints,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        isDense: widget.compact,
        contentPadding: widget.compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
            : null,
        labelText: widget.label,
        prefixIcon: Icon(widget.icon, size: 20),
        suffixIcon: widget.secret
            ? IconButton(
                tooltip: _visible
                    ? 'Hide ${widget.label}'
                    : 'Show ${widget.label}',
                onPressed: () => setState(() => _visible = !_visible),
                icon: Icon(
                  _visible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              )
            : null,
      ),
    ),
  );
}

class _Feedback extends StatelessWidget {
  const _Feedback(this.state);
  final AuthState state;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (state.error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Semantics(
            liveRegion: true,
            child: Text(
              state.error!,
              style: const TextStyle(color: Color(0xFFFFB6BB)),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      if (state.message != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Semantics(
            liveRegion: true,
            child: Text(
              state.message!,
              style: const TextStyle(color: Color(0xFF84F2EB)),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      if (state.busy)
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: LinearProgressIndicator(),
        ),
    ],
  );
}

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final vm = ref.read(authViewModelProvider.notifier);
    final repository = ref.watch(authRepositoryProvider);
    return _AuthLayout(
      title: 'Sign In',
      header: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: const ValueKey('auth-language'),
          value: state.language.isEmpty
              ? repository.languages.first
              : state.language,
          items: repository.languages
              .map(
                (language) => DropdownMenuItem(
                  value: language,
                  child: Text(language, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) vm.setLanguage(value);
          },
        ),
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Feedback(state),
            _AuthField(
              fieldKey: const ValueKey('auth-email'),
              label: 'Email',
              value: state.email,
              icon: Icons.mail_outline_rounded,
              keyboard: TextInputType.emailAddress,
              validator: AuthValidators.email,
              autofillHints: const [AutofillHints.username],
              onChanged: (value) => vm.updateSignIn(email: value),
            ),
            _AuthField(
              fieldKey: const ValueKey('auth-password'),
              label: 'Password',
              value: state.password,
              icon: Icons.lock_outline_rounded,
              secret: true,
              autofillHints: const [AutofillHints.password],
              validator: (value) => value == null || value.isEmpty
                  ? 'Enter your password.'
                  : null,
              onChanged: (value) => vm.updateSignIn(password: value),
            ),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: state.rememberMe,
                      onChanged: (value) =>
                          vm.updateSignIn(rememberMe: value ?? false),
                    ),
                    const Text('Remember me', style: TextStyle(fontSize: 12)),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    vm.clearFeedback();
                    context.push('/forgot-password');
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            NeonButton(
              key: const ValueKey('auth-sign-in'),
              label: 'Sign In',
              icon: Icons.arrow_forward_rounded,
              onPressed: state.busy || !state.initialized
                  ? null
                  : () {
                      if (_form.currentState!.validate()) {
                        _navigate(context, vm.signIn());
                      }
                    },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                vm.clearFeedback();
                context.push('/register');
              },
              child: const Text('Create Account'),
            ),
            const Divider(height: 24),
            TextButton.icon(
              key: const ValueKey('auth-demo-fill'),
              onPressed: vm.useDemoCredentials,
              icon: const Icon(Icons.science_outlined, size: 18),
              label: const Text('Use demo account'),
            ),
            Text(
              '${repository.demoEmail}\n${repository.demoPassword}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFFB8D8DF)),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Simulate offline',
                style: TextStyle(fontSize: 12),
              ),
              subtitle: const Text(
                'Demo Retry / Cancel flow',
                style: TextStyle(fontSize: 10),
              ),
              value: state.simulateOffline,
              onChanged: vm.setOffline,
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take profile photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final vm = ref.read(authViewModelProvider.notifier);
    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        maxWidth: 640,
        imageQuality: 80,
      );
      if (photo == null || !mounted) return;
      final bytes = await photo.readAsBytes();
      if (mounted) vm.attachPhoto(photo.path, bytes);
    } on PlatformException {
      vm.reportPhotoUnavailable();
    } on MissingPluginException {
      vm.reportPhotoUnavailable();
    } on UnsupportedError {
      vm.reportPhotoUnavailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final vm = ref.read(authViewModelProvider.notifier);
    final draft = state.registration;
    return _AuthLayout(
      title: 'Create Account',
      fixedRegister: true,
      backRoute: '/sign-in',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Semantics(
                button: true,
                label: 'Add profile photo',
                child: InkWell(
                  onTap: _pickPhoto,
                  borderRadius: BorderRadius.circular(40),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0x5527CBE0),
                    backgroundImage: draft.avatarBytes == null
                        ? null
                        : MemoryImage(draft.avatarBytes!),
                    child: draft.avatarBytes == null
                        ? const Icon(Icons.add_a_photo_outlined, size: 30)
                        : null,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 33,
              child: TextButton(
                onPressed: _pickPhoto,
                child: Text(
                  draft.avatarBytes == null
                      ? 'Add Profile Photo (optional)'
                      : 'Change Profile Photo',
                ),
              ),
            ),
            _Feedback(state),
            _AuthField(
              fieldKey: const ValueKey('register-name'),
              compact: true,
              label: 'Full Name',
              value: draft.name,
              icon: Icons.person_outline,
              validator: AuthValidators.name,
              onChanged: (value) =>
                  vm.updateRegistration(draft.copyWith(name: value)),
            ),
            _AuthField(
              fieldKey: const ValueKey('register-email'),
              compact: true,
              label: 'Email',
              value: draft.email,
              icon: Icons.mail_outline,
              validator: AuthValidators.email,
              keyboard: TextInputType.emailAddress,
              onChanged: (value) =>
                  vm.updateRegistration(draft.copyWith(email: value)),
            ),
            _AuthField(
              fieldKey: const ValueKey('register-phone'),
              compact: true,
              label: 'Phone Number',
              value: draft.phone,
              icon: Icons.phone_outlined,
              validator: AuthValidators.phone,
              keyboard: TextInputType.phone,
              onChanged: (value) =>
                  vm.updateRegistration(draft.copyWith(phone: value)),
            ),
            _AuthField(
              fieldKey: const ValueKey('register-password'),
              compact: true,
              label: 'Password',
              value: draft.password,
              icon: Icons.lock_outline,
              secret: true,
              validator: AuthValidators.password,
              onChanged: (value) =>
                  vm.updateRegistration(draft.copyWith(password: value)),
            ),
            _AuthField(
              fieldKey: const ValueKey('register-confirm'),
              compact: true,
              label: 'Confirm Password',
              value: draft.confirm,
              icon: Icons.lock_outline,
              secret: true,
              validator: (value) =>
                  value != draft.password ? 'Passwords do not match.' : null,
              onChanged: (value) =>
                  vm.updateRegistration(draft.copyWith(confirm: value)),
            ),
            Row(
              children: [
                Checkbox(
                  key: const ValueKey('register-terms'),
                  value: draft.acceptedTerms,
                  onChanged: (value) => vm.updateRegistration(
                    draft.copyWith(acceptedTerms: value ?? false),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Demo Terms & Conditions'),
                        content: const Text(
                          'This is a local UI prototype. No real account is created and no email or SMS is sent. Enter demonstration details only. Demo accounts and passwords reset when the app restarts.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                    child: const Text(
                      'I agree to Terms & Conditions',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            NeonButton(
              key: const ValueKey('register-submit'),
              label: 'Create Account',
              onPressed: () {
                if (_form.currentState!.validate()) {
                  _navigate(context, vm.register());
                }
              },
            ),
            TextButton(
              onPressed: () => context.go('/sign-in'),
              child: const Text('Back to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final vm = ref.read(authViewModelProvider.notifier);
    return _AuthLayout(
      title: 'Forgot Password',
      backRoute: '/sign-in',
      subtitle: 'Enter your email to receive a demo OTP code.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Feedback(state),
            _AuthField(
              fieldKey: const ValueKey('forgot-email'),
              label: 'Email',
              value: state.recoveryEmail,
              icon: Icons.mail_outline,
              keyboard: TextInputType.emailAddress,
              validator: AuthValidators.email,
              onChanged: vm.updateRecoveryEmail,
            ),
            NeonButton(
              key: const ValueKey('forgot-submit'),
              label: 'Send OTP',
              onPressed: () {
                if (_form.currentState!.validate()) {
                  _navigate(context, vm.forgotPassword());
                }
              },
            ),
            TextButton(
              onPressed: () => context.go('/sign-in'),
              child: const Text('Back to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpScreen extends ConsumerWidget {
  const OtpScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authViewModelProvider);
    final vm = ref.read(authViewModelProvider.notifier);
    final origin = state.flow == OtpPurpose.registration
        ? '/register'
        : '/forgot-password';
    return _AuthLayout(
      title: 'OTP Verification',
      backRoute: origin,
      onBack: () {
        vm.abandonOtp();
        context.go(origin);
      },
      subtitle: 'Enter the six-digit code for\n${state.otpEmail}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            size: 40,
            color: Color(0xFF48EBE4),
          ),
          const SizedBox(height: 20),
          _Feedback(state),
          _AuthField(
            fieldKey: const ValueKey('auth-otp'),
            label: '6-digit demo code',
            value: state.otp,
            icon: Icons.pin_outlined,
            keyboard: TextInputType.number,
            maxLength: 6,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: vm.updateOtp,
          ),
          NeonButton(
            key: const ValueKey('otp-verify'),
            label: 'Verify',
            icon: Icons.check_circle_outline,
            accent: const Color(0xFFFFBA32),
            onPressed: () => _navigate(context, vm.verifyOtp()),
          ),
          TextButton(
            onPressed: () => _navigate(context, vm.resendOtp()),
            child: const Text('Resend OTP'),
          ),
          const Text(
            'Code expires in 5 minutes. Resend is available after 30 seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 16),
          Text(
            'DEMO OTP: ${ref.watch(authRepositoryProvider).demoOtp}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD477),
            ),
          ),
          TextButton(
            onPressed: () {
              vm.abandonOtp();
              context.go(origin);
            },
            child: const Text('Back to form'),
          ),
        ],
      ),
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final vm = ref.read(authViewModelProvider.notifier);
    return _AuthLayout(
      title: 'Reset Password',
      backRoute: '/forgot-password',
      onBack: () {
        vm.abandonOtp();
        context.go('/forgot-password');
      },
      subtitle: 'Choose a new password for your local demo account.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Feedback(state),
            _AuthField(
              fieldKey: const ValueKey('reset-password'),
              label: 'New Password',
              value: state.newPassword,
              icon: Icons.lock_outline,
              secret: true,
              validator: AuthValidators.password,
              onChanged: (value) => vm.updateReset(password: value),
            ),
            _AuthField(
              fieldKey: const ValueKey('reset-confirm'),
              label: 'Confirm New Password',
              value: state.confirmPassword,
              icon: Icons.lock_outline,
              secret: true,
              validator: (value) =>
                  value != state.newPassword ? 'Passwords do not match.' : null,
              onChanged: (value) => vm.updateReset(confirm: value),
            ),
            const Text(
              'Use at least 8 characters. Demo passwords are kept in memory only.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 20),
            NeonButton(
              key: const ValueKey('reset-submit'),
              label: 'Save Password',
              onPressed: () {
                if (_form.currentState!.validate()) {
                  _navigate(context, vm.resetPassword());
                }
              },
            ),
            TextButton(
              onPressed: () {
                vm.abandonOtp();
                context.go('/sign-in');
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class OfflineScreen extends ConsumerWidget {
  const OfflineScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) context.go('/cancel-auth');
    },
    child: _AuthLayout(
      title: 'No Internet Connection',
      subtitle: 'DEMO offline simulation. Your form and interrupted action are preserved. No network request was made.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 54,
            color: Color(0xFF58E8F2),
          ),
          const SizedBox(height: 24),
          NeonButton(
            key: const ValueKey('offline-retry'),
            label: 'Retry',
            icon: Icons.refresh_rounded,
            accent: const Color(0xFFFFBA32),
            onPressed: () {
              ref.read(authViewModelProvider.notifier).restoreConnection();
              context.go('/connection-restored');
            },
          ),
          TextButton(
            onPressed: () => context.go('/cancel-auth'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

class ConnectionRestoredScreen extends ConsumerWidget {
  const ConnectionRestoredScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _AuthLayout(
    title: 'Connection Restored',
    backRoute: '/offline',
    subtitle: 'DEMO connection restored. Resume the interrupted action once, or return to your form.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 56,
          color: Color(0xFF58F1AE),
        ),
        const SizedBox(height: 24),
        NeonButton(
          key: const ValueKey('offline-resume'),
          label: 'Resume',
          icon: Icons.play_arrow_rounded,
          onPressed: () => _navigate(
            context,
            ref.read(authViewModelProvider.notifier).resumePending(),
          ),
        ),
        TextButton(
          onPressed: () => context.go(
            ref.read(authViewModelProvider.notifier).cancelPending(),
          ),
          child: const Text('Return to form'),
        ),
      ],
    ),
  );
}

class CancelAuthScreen extends ConsumerWidget {
  const CancelAuthScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _AuthLayout(
    title: 'Cancel and Go Back?',
    backRoute: '/offline',
    subtitle: 'Return to your form without submitting? Your entered details will stay here.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 48,
          color: Color(0xFFFFD477),
        ),
        const SizedBox(height: 24),
        NeonButton(
          label: 'Go Back',
          icon: Icons.arrow_back_rounded,
          onPressed: () => context.go(
            ref.read(authViewModelProvider.notifier).cancelPending(),
          ),
        ),
        TextButton(
          onPressed: () => context.go('/offline'),
          child: const Text('Stay Here'),
        ),
      ],
    ),
  );
}

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});
  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    await ref.read(authViewModelProvider.notifier).completePermissions();
    if (context.mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authViewModelProvider);
    final vm = ref.read(authViewModelProvider.notifier);
    Widget permission(
      String id,
      String title,
      String description,
      IconData icon,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: const Color(0xFF5AEFE6)),
            title: Text(title),
            subtitle: Text(description),
          ),
          if (state.permissionStatus[id] != null)
            Text(
              state.permissionStatus[id]!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFFFD477)),
            ),
          OutlinedButton(
            onPressed: state.busy || state.permissionStatus.containsKey(id)
                ? null
                : () => vm.requestPermission(id),
            child: Text('Allow $title'),
          ),
        ],
      ),
    );
    return PopScope(
      canPop: false,
      child: _AuthLayout(
        title: 'Allow Permissions',
        subtitle: 'Choose what Wayhunter can access. You can continue with every permission denied.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Feedback(state),
            permission(
              'location',
              'Location',
              'For device location in map features. Demo places remain available.',
              Icons.location_on_outlined,
            ),
            permission(
              'camera',
              'Camera',
              'For optional photos. Hunter evidence is planned for a later phase.',
              Icons.camera_alt_outlined,
            ),
            permission(
              'notifications',
              'Notifications',
              'Permission only. This prototype sends no push notifications.',
              Icons.notifications_outlined,
            ),
            TextButton(
              onPressed: () async {
                final opened = await ref
                    .read(devicePermissionServiceProvider)
                    .openSettings();
                if (context.mounted && !opened) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Device settings are unavailable here. Continue in demo mode.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Open device settings'),
            ),
            NeonButton(
              key: const ValueKey('permissions-continue'),
              label: 'Continue to Home',
              onPressed: state.busy ? null : () => _continue(context, ref),
            ),
            TextButton(
              onPressed: state.busy ? null : () => _continue(context, ref),
              child: const Text('Not Now'),
            ),
            const Text(
              'This introduction appears once for this local demo account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
