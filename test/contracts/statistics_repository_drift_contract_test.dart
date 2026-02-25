// Statistics Repository Hybrid Contract Test
// Runs the shared statistics contract tests against both SQLite and Drift engines.

import '../hybrid_test_runner.dart';
import 'statistics_repository_contract.dart';

void main() {
  runHybridTests('Statistics Repository Contract Tests', (base) {
    runStatisticsRepositoryContractTests(base);
  });
}
