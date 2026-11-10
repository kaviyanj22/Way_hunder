import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';

String cell(Object? value) => '$value'.replaceAll('|', '\\|').replaceAll('\n', ' ');

Future<void> main() async {
  await integrationDriver(
    timeout: const Duration(minutes: 45),
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      final incoming = (data?['screenIndex'] as List? ?? [])
          .map((r) => Map<String, dynamic>.from(r as Map)).toList();
      final manifest = File('screenshots/capture_manifest.json');
      final previous = await manifest.exists()
          ? (jsonDecode(await manifest.readAsString()) as List)
              .map((r) => Map<String, dynamic>.from(r as Map)).toList()
          : <Map<String, dynamic>>[];
      final replaced = {...?data?['modules'] as List?, ...incoming.map((r) => r['module'])};
      final partial = data?['partial'] == true;
      String rowKey(Map<String, dynamic> r) =>
          '${r['module']}|${r['screen']}|${r['route']}|${r['filename']}';
      final incomingKeys = incoming.map(rowKey).toSet();
      final failedModules = incoming.where((r) => r['status'] == 'Capture failed')
          .map((r) => r['module']).toSet();
      final names = incoming.map((r) => r['filename']).toSet();
      final exportRoot = Directory('screenshots').absolute.path;
      for (final row in previous.where((r) => !partial && replaced.contains(r['module']))) {
        final name = row['filename'] as String;
        if (name.isEmpty || names.contains(name)) continue;
        final stale = File('screenshots/$name').absolute;
        if (stale.path.startsWith('$exportRoot${Platform.pathSeparator}') &&
            stale.path.endsWith('.png') && await stale.exists()) {
          await stale.delete();
        }
      }
      final rows = [...previous.where((r) {
        if (!partial) return !replaced.contains(r['module']);
        if (incomingKeys.contains(rowKey(r))) return false;
        if ((r['filename'] as String).isNotEmpty && names.contains(r['filename'])) return false;
        if (r['status'] == 'Capture failed' && replaced.contains(r['module']) &&
            !failedModules.contains(r['module'])) return false;
        return true;
      }), ...incoming];
      final adb = Platform.environment['WAYHUNTER_ADB'] ?? 'adb';
      final serial = Platform.environment['WAYHUNTER_DEVICE'] ?? 'emulator-5554';
      for (final row in incoming.where((r) => r['status'] == 'Captured')) {
        final result = await Process.run(adb,
          ['-s', serial, 'exec-out', 'run-as', 'com.example.wayhunter_mobile',
            'cat', row['devicePath'] as String], stdoutEncoding: null);
        final bytes = result.stdout as List<int>;
        if (result.exitCode != 0 || bytes.length < 24 ||
            bytes.take(8).join(',') != '137,80,78,71,13,10,26,10') {
          row['status'] = 'Transfer failed';
          row['notes'] = 'adb failed: ${result.stderr}';
          continue;
        }
        final file = File('screenshots/${row['filename']}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
        stdout.writeln('EXPORTED ${row['filename']} (${bytes.length} bytes)');
      }
      final count = rows.where((r) => r['status'] == 'Captured').length;
      await Directory('screenshots').create(recursive: true);
      await File('screenshots/capture_manifest.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(rows));
      final md = StringBuffer('# Flutter screen export\n\n')
        ..writeln('Actual Android Flutter UI, 390 × 844 pixels. $count PNG files exported.')
        ..writeln('\nCapture run: ${DateTime.now().toUtc().toIso8601String()} (UTC).')
        ..writeln('\nIsolated existing MockData repositories and in-memory storage. '
          'Native maps/camera are not replaced. Long pages may have additional scroll captures. '
          'Prototype evidence and rewards use existing explicit demo actions.')
        ..writeln('\n| Module | Screen name | Route | Screenshot filename | Capture status | Notes |')
        ..writeln('|---|---|---|---|---|---|');
      for (final r in rows) {
        final filename = r['filename'] as String;
        md.writeln('| ${cell(r['module'])} | ${cell(r['screen'])} | '
          '`${cell(r['route'])}` | ${filename.isEmpty ? '—' : '[$filename]($filename)'} | '
          '${cell(r['status'])} | ${cell(r['notes'] ?? '')} |');
      }
      await File('screenshots/SCREEN_INDEX.md').writeAsString(md.toString());
      if (rows.any((r) => r['status'] == 'Transfer failed')) {
        throw StateError('One or more PNG transfers failed; see SCREEN_INDEX.md.');
      }
    },
  );
}
