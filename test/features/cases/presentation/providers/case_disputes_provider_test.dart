import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_dispute.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/case_disputes_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  CaseDisputesNotifier notifier([String caseId = 'case-1']) =>
      container.read(caseDisputesProvider(caseId).notifier);

  List<CaseDispute> disputes([String caseId = 'case-1']) =>
      container.read(caseDisputesProvider(caseId));

  test('starts empty', () => expect(disputes(), isEmpty));

  test('raise adds an open, trimmed dispute', () {
    final raised = notifier().raise(
      title: '  Wrong plot  ',
      description: ' The survey covers the next plot. ',
    );

    expect(disputes(), [raised]);
    expect(raised.title, 'Wrong plot');
    expect(raised.description, 'The survey covers the next plot.');
    expect(raised.isOpen, isTrue);
    expect(raised.respondedAt, isNull);
  });

  test('a case may carry several disputes, kept per case', () {
    notifier().raise(title: 'One', description: 'a');
    notifier().raise(title: 'Two', description: 'b');

    expect(disputes().map((d) => d.title), ['One', 'Two']);
    expect(disputes('case-2'), isEmpty);
  });

  test('taking in closes the dispute with a time', () {
    final raised = notifier().raise(title: 'One', description: 'a');
    notifier().takeIn(raised.id);

    final answered = disputes().single;
    expect(answered.status, DisputeStatus.takenIn);
    expect(answered.respondedAt, isNotNull);
    expect(answered.declineNote, isNull);
  });

  test('declining keeps the note', () {
    final raised = notifier().raise(title: 'One', description: 'a');
    notifier().decline(raised.id, '  Report stands.  ');

    final answered = disputes().single;
    expect(answered.status, DisputeStatus.declined);
    expect(answered.declineNote, 'Report stands.');
  });

  test('an answered dispute cannot be answered again', () {
    final raised = notifier().raise(title: 'One', description: 'a');
    notifier().takeIn(raised.id);
    notifier().decline(raised.id, 'Too late');

    expect(disputes().single.status, DisputeStatus.takenIn);
  });
}
