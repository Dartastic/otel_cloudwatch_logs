// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_cloudwatch_logs_suppression.dart';

const _tracerName = 'dartastic_otel_libs_cloudwatch_logs';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps a CloudWatch Logs `PutLogEvents` call in a CLIENT span,
/// recording the log group + stream targets.
Future<T> tracedCloudwatchLogsPutLogEvents<T>({
  required String logGroup,
  required String logStream,
  required Future<T> Function() invoke,
  int? eventCount,
  String? region,
}) async {
  if (cloudwatchLogsInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'rpc.system': 'aws-api',
    'rpc.service': 'CloudWatchLogs',
    'rpc.method': 'PutLogEvents',
    'aws.log.group.name': logGroup,
    'aws.log.stream.name': logStream,
  };
  if (eventCount != null) m['messaging.batch.message_count'] = eventCount;
  if (region != null) m['cloud.region'] = region;

  final span = _tracer().startSpan(
    'cloudwatch_logs put $logGroup',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
