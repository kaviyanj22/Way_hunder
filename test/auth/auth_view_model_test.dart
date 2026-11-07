import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/core/mock/mock_data.dart';
import 'package:wayhunter_mobile/core/storage/local_demo_storage.dart';
import 'package:wayhunter_mobile/features/auth/domain/auth_repository.dart';
import 'package:wayhunter_mobile/features/auth/presentation/viewmodels/auth_view_model.dart';

void main() {
  late ProviderContainer container;
  late AuthViewModel vm;
  late DateTime now;
  const registration = RegistrationDraft(
    name: 'Test Explorer',
    email: 'new.explorer@example.test',
    phone: '+94 77 123 4567',
    password: 'testPassword9',
    confirm: 'testPassword9',
    acceptedTerms: true,
  );

  setUp(() async {
    now = DateTime(2026, 11, 5, 12);
    container = ProviderContainer(
      overrides: [
        localDemoStorageProvider.overrideWithValue(MemoryDemoStorage()),
        authClockProvider.overrideWithValue(() => now),
      ],
    );
    vm = container.read(authViewModelProvider.notifier);
    await vm.initialize();
  });
  tearDown(() => container.dispose());

  test(
    'demo login uses central fixture and rejects incorrect credentials',
    () async {
      vm.updateSignIn(email: MockData.demoEmail, password: 'incorrect');
      expect(await vm.signIn(), isNull);
      expect(
        container.read(authViewModelProvider).error,
        contains('incorrect'),
      );
      vm.useDemoCredentials();
      expect(await vm.signIn(), '/home');
      final state = container.read(authViewModelProvider);
      expect(state.user!.name, MockData.currentUser['name']);
      expect(state.user!.hp, MockData.currentUser['hp']);
      expect(state.password, isEmpty);
    },
  );

  test(
    'registration requires valid details and verified OTP before login',
    () async {
      vm.updateRegistration(registration.copyWith(acceptedTerms: false));
      expect(await vm.register(), isNull);
      vm.updateRegistration(registration);
      expect(await vm.register(), '/otp');
      expect(
        container
            .read(authRepositoryProvider)
            .accountExists(registration.email),
        isFalse,
      );
      vm.updateOtp('000000');
      expect(await vm.verifyOtp(), isNull);
      vm.updateOtp(MockData.demoOtp);
      expect(await vm.verifyOtp(), '/sign-in');
      expect(container.read(authViewModelProvider).user, isNull);
      vm.updateSignIn(
        email: registration.email,
        password: registration.password,
      );
      expect(await vm.signIn(), '/permissions');
      await vm.completePermissions();
      vm.signOut();
      vm.updateSignIn(
        email: registration.email,
        password: registration.password,
      );
      expect(await vm.signIn(), '/home');
      vm.signOut();
      vm.updateRegistration(registration);
      expect(await vm.register(), isNull);
      expect(container.read(authViewModelProvider).error, contains('already'));
    },
  );

  test(
    'recovery cannot reset before OTP and replaces the local password',
    () async {
      vm.updateReset(
        password: 'replacementPassword7',
        confirm: 'replacementPassword7',
      );
      expect(await vm.resetPassword(), isNull);
      vm.updateRecoveryEmail(MockData.demoEmail);
      expect(await vm.forgotPassword(), '/otp');
      vm.updateOtp(MockData.demoOtp);
      expect(await vm.verifyOtp(), '/reset-password');
      expect(await vm.resetPassword(), '/sign-in');
      vm.useDemoCredentials();
      expect(await vm.signIn(), isNull);
      vm.updateSignIn(password: 'replacementPassword7');
      expect(await vm.signIn(), '/home');
    },
  );

  test('OTP expiry and resend cooldown use injected clock', () async {
    vm.updateRegistration(registration);
    await vm.register();
    expect(await vm.resendOtp(), isNull);
    now = now.add(const Duration(minutes: 6));
    vm.updateOtp(MockData.demoOtp);
    expect(await vm.verifyOtp(), isNull);
    expect(container.read(authViewModelProvider).error, contains('expired'));
    expect(await vm.resendOtp(), '/otp');
    vm.updateOtp(MockData.demoOtp);
    expect(await vm.verifyOtp(), '/sign-in');
  });

  test('offline cancel preserves form, retry resumes signup once', () async {
    vm.updateRegistration(registration);
    vm.setOffline(true);
    expect(await vm.register(), '/offline');
    expect(vm.cancelPending(), '/register');
    expect(
      container.read(authViewModelProvider).registration.email,
      registration.email,
    );
    vm.setOffline(true);
    expect(await vm.register(), '/offline');
    vm.restoreConnection();
    expect(await vm.resumePending(), '/otp');
    expect(container.read(authViewModelProvider).pendingAction, isNull);
    vm.updateOtp(MockData.demoOtp);
    expect(await vm.verifyOtp(), '/sign-in');
    expect(await vm.resumePending(), '/register');
    expect(
      container.read(authRepositoryProvider).accountExists(registration.email),
      isTrue,
    );
  });

  test(
    'remember me stores email only and language survives a new container',
    () async {
      vm.useDemoCredentials();
      vm.updateSignIn(rememberMe: true);
      await vm.setLanguage(MockData.languageOptions.last);
      await vm.signIn();
      final storage = container.read(localDemoStorageProvider);
      expect(await storage.readString('rememberedEmail'), MockData.demoEmail);
      expect(await storage.readString('password'), isNull);
      final next = ProviderContainer(
        overrides: [localDemoStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(next.dispose);
      await next.read(authViewModelProvider.notifier).initialize();
      expect(next.read(authViewModelProvider).email, MockData.demoEmail);
      expect(next.read(authViewModelProvider).password, isEmpty);
      expect(
        next.read(authViewModelProvider).language,
        MockData.languageOptions.last,
      );
      expect(next.read(authViewModelProvider).user, isNull);
    },
  );

  test(
    'repository validates duplicate fixture email without fixture copies',
    () {
      final repository = container.read(authRepositoryProvider);
      expect(
        () => repository.validateRegistration(
          registration.copyWith(email: MockData.demoEmail),
        ),
        throwsA(isA<AuthFailure>()),
      );
    },
  );
}
