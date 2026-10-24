// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_cloudwatch_logs/otel_cloudwatch_logs.dart';

/// Traces CloudWatch Logs `PutLogEvents` calls with OpenTelemetry.
///
/// `otel_cloudwatch_logs` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each CloudWatch Logs `PutLogEvents` call in
/// [tracedCloudwatchLogsPutLogEvents]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'cloudwatch-logs-example');

  // Wraps a CloudWatch Logs PutLogEvents call in a CLIENT span, recording the log group + stream targets.
  final cloudwatchLogsPutLogEventsId =
      await tracedCloudwatchLogsPutLogEvents<String>(
    logGroup: 'example',
    logStream: 'example',
    eventCount: 3,
    region: 'us-east-1',
    invoke: () async {
      // Make the CloudWatch Logs `PutLogEvents` call here, then report what it returned.
      return 'cloudwatch_logs_8f3a2c';
    },
  );
  OTelLog.info(
      'tracedCloudwatchLogsPutLogEvents returned $cloudwatchLogsPutLogEventsId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutCloudwatchLogsInstrumentationAsync.
  await runWithoutCloudwatchLogsInstrumentationAsync(
    () => tracedCloudwatchLogsPutLogEvents<String>(
      logGroup: 'example',
      logStream: 'example',
      eventCount: 3,
      region: 'us-east-1',
      invoke: () async {
        return 'cloudwatch_logs_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
