/// Pure domain services (no Flutter, no Firebase).
///
/// Public API contract shared by data/presentation. Implementations live in
/// the sibling files and are exported here.
library;

export 'audit_service.dart';
export 'bingo_verifier.dart';
export 'card_generator.dart';
export 'draw_sequence.dart';
export 'pattern_detector.dart';
export 'penalty_evaluator.dart';
export 'prize_policy_evaluator.dart';
export 'tie_breaker.dart';
export 'underdog_calculator.dart';
