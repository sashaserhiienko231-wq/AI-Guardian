import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ProcessFinding {
  const ProcessFinding({
    required this.processId,
    required this.name,
    required this.reason,
  });

  final int processId;
  final String name;
  final String reason;

  factory ProcessFinding.fromMap(Map<Object?, Object?> value) {
    return ProcessFinding(
      processId: value['pid'] as int,
      name: value['name'] as String,
      reason: value['reason'] as String,
    );
  }
}

class ProcessScanner {
  static const _channel = MethodChannel('ai_guardian/process_scanner');

  static bool get isSupported => defaultTargetPlatform == TargetPlatform.windows;

  Future<ProcessScanReport> scan() async {
    if (!isSupported) {
      throw UnsupportedError('Process scanning is currently available on Windows only.');
    }

    final value = await _channel.invokeMapMethod<Object?, Object?>('scanProcesses');
    if (value == null) {
      throw PlatformException(
        code: 'invalid_process_scan',
        message: 'Windows returned no process scan result.',
      );
    }

    final processes = value['findings'] as List<Object?>;
    return ProcessScanReport(
      findings: processes
          .cast<Map<Object?, Object?>>()
          .map(ProcessFinding.fromMap)
          .toList(growable: false),
      unreadableProcesses: value['unreadable_processes'] as int,
    );
  }
}

class ProcessScanReport {
  const ProcessScanReport({
    required this.findings,
    required this.unreadableProcesses,
  });

  final List<ProcessFinding> findings;
  final int unreadableProcesses;
}
