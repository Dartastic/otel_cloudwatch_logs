// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_cloudwatch_logs/otel_cloudwatch_logs.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_cloudwatch_logs-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('PutLogEvents records CLIENT span', () async {
    await tracedCloudwatchLogsPutLogEvents<String>(
      logGroup: '/aws/lambda/orders',
      logStream: r'2026/05/14/[$LATEST]abc',
      eventCount: 12,
      region: 'us-east-1',
      invoke: () async => 'ok',
    );
    final span = spans.findSpanByName('cloudwatch_logs put /aws/lambda/orders');
    expect(span, isNotNull);
    expect(span!.kind, SpanKind.client);
    final a = attrsOf(span);
    expect(a['rpc.system'], 'aws-api');
    expect(a['rpc.service'], 'CloudWatchLogs');
    expect(a['rpc.method'], 'PutLogEvents');
    expect(a['aws.log.group.name'], '/aws/lambda/orders');
    expect(a['aws.log.stream.name'], '2026/05/14/[\$LATEST]abc');
    expect(a['messaging.batch.message_count'], 12);
    expect(a['cloud.region'], 'us-east-1');
  });

  test('records exception', () async {
    await expectLater(
      tracedCloudwatchLogsPutLogEvents<String>(
        logGroup: 'g',
        logStream: 's',
        invoke: () async => throw StateError('boom'),
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      spans.findSpanByName('cloudwatch_logs put g')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutCloudwatchLogsInstrumentationAsync(() async {
      await tracedCloudwatchLogsPutLogEvents<String>(
        logGroup: 'g',
        logStream: 's',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('cloudwatch_logs '), isEmpty);
  });
}
