import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wayhunter_mobile/core/services/device_permission_service.dart';
import 'package:wayhunter_mobile/core/services/maps_service.dart';
import 'package:wayhunter_mobile/core/storage/local_demo_storage.dart';
import 'package:wayhunter_mobile/core/widgets/demo_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('wayhunter/device');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void useAndroidPlatform() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'Maps uses the native configured boolean without receiving a key',
    () async {
      useAndroidPlatform();
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });

      expect(await MapsService().availability(), MapsAvailability.configured);
      expect(calls.single.method, 'mapsConfigured');
      expect(calls.single.arguments, isNull);
    },
  );

  test('Maps treats absent key and native errors as unavailable', () async {
    useAndroidPlatform();
    messenger.setMockMethodCallHandler(channel, (call) async => false);
    expect(await MapsService().availability(), MapsAvailability.missingKey);
    expect(await MapsService().isConfigured(), isFalse);

    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'configuration_unavailable');
    });
    expect(await MapsService().availability(), MapsAvailability.missingKey);
  });

  test(
    'Maps safely handles a missing plugin and an unsupported platform',
    () async {
      useAndroidPlatform();
      expect(await MapsService().availability(), MapsAvailability.unsupported);

      var nativeCalls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        nativeCalls++;
        return true;
      });
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(await MapsService().availability(), MapsAvailability.unsupported);
      expect(nativeCalls, 0);
    },
  );

  testWidgets('missing Maps key renders fallback without a platform map', (
    tester,
  ) async {
    var checks = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      checks++;
      return false;
    });
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: DemoMap())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Google Maps needs setup'), findsOneWidget);
    expect(find.byType(GoogleMap), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Check map availability'));
    await tester.pumpAndSettle();
    expect(checks, 2);
    expect(find.byType(GoogleMap), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  test(
    'permission service explains missing plugins and platform errors',
    () async {
      useAndroidPlatform();
      final service = DevicePermissionService();
      expect(await service.requestCamera(), contains('Unavailable'));
      expect(await service.requestNotifications(), contains('Unavailable'));

      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'permission_unavailable');
      });
      expect(await service.requestCamera(), contains('continue without'));
      expect(
        await service.requestNotifications(),
        contains('continue without'),
      );
    },
  );

  test(
    'native permission denial is returned honestly without requesting capture',
    () async {
      useAndroidPlatform();
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return 'Denied. Continue without this permission.';
      });
      final service = DevicePermissionService();
      expect(await service.requestCamera(), startsWith('Denied'));
      expect(await service.requestNotifications(), startsWith('Denied'));
      expect(calls, ['requestCamera', 'requestNotifications']);
    },
  );

  test('unsupported devices keep permissions and settings optional', () async {
    useAndroidPlatform();
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final service = DevicePermissionService();
    expect(await service.requestLocation(), contains('Unavailable'));
    expect(await service.requestCamera(), contains('Unavailable'));
    expect(await service.requestNotifications(), contains('Unavailable'));
    expect(await service.openSettings(), isFalse);
  });

  test('memory storage retains typed values and removes preferences', () async {
    final storage = MemoryDemoStorage();
    expect(await storage.readBool('permissions'), isNull);
    expect(await storage.readString('language'), isNull);

    await storage.writeBool('permissions', true);
    await storage.writeString('language', 'selected-language');
    expect(await storage.readBool('permissions'), isTrue);
    expect(await storage.readString('language'), 'selected-language');

    await storage.writeBool('permissions', false);
    expect(await storage.readBool('permissions'), isFalse);
    await storage.remove('permissions');
    expect(await storage.readBool('permissions'), isNull);
    expect(await storage.readString('language'), 'selected-language');
  });
}
