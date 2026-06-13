import 'dart:io';

import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';

/// Loads a recorded session-trace fixture from
/// `test/fixtures/auto_scorer_sessions/<name>.jsonl`. `flutter test` runs with
/// the package root as the working directory, so the relative path resolves.
///
/// Drop a real device-exported trace (sub-issue #492) here to turn a reported
/// auto-scorer bug into a deterministic regression test.
SessionTrace loadTrace(String name) => SessionTrace.fromJsonl(
      File('test/fixtures/auto_scorer_sessions/$name.jsonl').readAsStringSync(),
    );
