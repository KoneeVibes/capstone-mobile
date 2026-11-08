import 'package:equatable/equatable.dart';

/// The client Home's four counts over their own cases, as the backend counts
/// them (ADR 0028).
class CaseOverview extends Equatable {
  const CaseOverview({
    required this.total,
    required this.reportsReady,
    required this.inProgress,
    required this.needsInput,
  });

  final int total;
  final int reportsReady;
  final int inProgress;
  final int needsInput;

  @override
  List<Object?> get props => [total, reportsReady, inProgress, needsInput];
}
