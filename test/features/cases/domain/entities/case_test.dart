import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_applicant.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_filter.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_property.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_status.dart';

import '../../case_fixtures.dart';

void main() {
  group('CaseStatus.fromApi', () {
    test('parses every value the API documents', () {
      expect(CaseStatus.fromApi('submitted'), CaseStatus.submitted);
      expect(
        CaseStatus.fromApi('payment-validated'),
        CaseStatus.paymentValidated,
      );
      expect(CaseStatus.fromApi('assigned'), CaseStatus.assigned);
      expect(CaseStatus.fromApi('accepted'), CaseStatus.accepted);
      expect(
        CaseStatus.fromApi('pending-information'),
        CaseStatus.pendingInformation,
      );
      expect(CaseStatus.fromApi('under-review'), CaseStatus.underReview);
      expect(CaseStatus.fromApi('closed'), CaseStatus.closed);
      expect(CaseStatus.fromApi('suspended'), CaseStatus.suspended);
    });

    test('is forgiving about case and padding', () {
      expect(CaseStatus.fromApi('  Under-Review '), CaseStatus.underReview);
    });

    test('falls back to unknown rather than throwing', () {
      expect(CaseStatus.fromApi('archived'), CaseStatus.unknown);
      expect(CaseStatus.fromApi(null), CaseStatus.unknown);
      expect(CaseStatus.unknown.isKnown, isFalse);
    });

    test('submitted is the only status that cannot be assigned', () {
      expect(CaseStatus.submitted.canBeAssigned, isFalse);
      for (final status in CaseStatus.values) {
        if (status == CaseStatus.submitted) continue;
        expect(status.canBeAssigned, isTrue, reason: status.name);
      }
    });

    test('a status this build does not know stays assignable', () {
      // Deliberate: refusing here would let a status added server-side
      // silently disable the one action the detail screen has.
      expect(CaseStatus.unknown.canBeAssigned, isTrue);
    });

    test('only payment-validated advances when assigned', () {
      expect(CaseStatus.paymentValidated.advancesOnAssign, isTrue);
      for (final status in CaseStatus.values) {
        if (status == CaseStatus.paymentValidated) continue;
        expect(status.advancesOnAssign, isFalse, reason: status.name);
      }
    });
  });

  group('CaseApplicant.initials', () {
    test('takes the first and last word, skipping a middle name', () {
      const applicant = CaseApplicant(name: 'Ofofonono Okon Umoren');
      expect(applicant.initials, 'OU');
    });

    test('falls back to two letters of a single name', () {
      expect(const CaseApplicant(name: 'Ada').initials, 'AD');
    });

    test('survives a blank name', () {
      expect(const CaseApplicant(name: '   ').initials, '');
    });
  });

  group('CaseProperty', () {
    test('location is the coarse city and state', () {
      const property = CaseProperty(
        type: 'building',
        address: '5 Kayode Abraham',
        city: 'Victoria Island',
        lga: 'Eti-Osa',
        state: 'Lagos',
      );
      expect(property.location, 'Victoria Island, Lagos');
      expect(
        property.fullAddress,
        '5 Kayode Abraham, Victoria Island, Eti-Osa, Lagos',
      );
    });

    test('skips the parts a half-filled record is missing', () {
      const property = CaseProperty(type: 'land', state: 'Lagos');
      expect(property.location, 'Lagos');
      expect(property.fullAddress, 'Lagos');
    });

    test('does not repeat a city the address already names', () {
      // A real record: the web form's free-text address restates the city and
      // state, which appended naively read
      // `12 Allen Avenue, Ikeja, Lagos, Ikeja, Ikeja, Lagos`.
      const property = CaseProperty(
        type: 'land',
        address: '12 Allen Avenue, Ikeja, Lagos',
        city: 'Ikeja',
        lga: 'Ikeja',
        state: 'Lagos',
      );

      expect(property.fullAddress, '12 Allen Avenue, Ikeja, Lagos');
      expect(property.location, 'Ikeja, Lagos');
    });

    test('matches a repeat regardless of case or padding', () {
      const property = CaseProperty(
        type: 'land',
        address: '12 Allen Avenue,  IKEJA ',
        city: 'Ikeja',
        state: 'Lagos',
      );

      expect(property.fullAddress, '12 Allen Avenue, IKEJA, Lagos');
    });

    test('collapses a city and state that are the same place', () {
      const property = CaseProperty(type: 'land', city: 'Lagos', state: 'Lagos');
      expect(property.location, 'Lagos');
    });

    test('labels the type from the API value', () {
      expect(const CaseProperty(type: 'building').typeLabel, 'Building');
      expect(const CaseProperty(type: '').typeLabel, '');
    });

    test('hasDocuments covers either kind of attachment', () {
      expect(const CaseProperty(type: 'land').hasDocuments, isFalse);
      expect(
        const CaseProperty(type: 'land', surveyPlans: ['a']).hasDocuments,
        isTrue,
      );
      expect(
        const CaseProperty(type: 'land', titleDocuments: ['b']).hasDocuments,
        isTrue,
      );
    });
  });

  group('Case.summary', () {
    test('joins property type and location', () {
      expect(buildCase().summary, 'Building · Victoria Island, Lagos');
    });

    test('drops a part the record does not carry', () {
      expect(
        buildCase(city: null, state: null).summary,
        'Building',
      );
      expect(
        buildCase(propertyType: '').summary,
        'Victoria Island, Lagos',
      );
    });
  });

  group('Case.purposeLabel', () {
    test('renders kebab-cased purposes as a readable list', () {
      expect(
        buildCase(
          inquiryPurpose: const ['due-diligence', 'physical-inspection'],
        ).purposeLabel,
        'Due diligence, Physical inspection',
      );
    });

    test('is empty when none were given', () {
      expect(buildCase(inquiryPurpose: const []).purposeLabel, '');
    });
  });

  group('Case.isAssigned', () {
    test('follows the assignee id, not the resolved name', () {
      expect(buildCase().isAssigned, isFalse);
      expect(buildCase(assignee: ada).isAssigned, isTrue);
    });

    test('stays true when the name could not be resolved', () {
      // A staff member since deactivated, or a staff request that failed. The
      // case still belongs to somebody and must not read as unassigned.
      final value = buildCase(assigneeId: 'staff-9');
      expect(value.isAssigned, isTrue);
      expect(value.assignee, isNull);
    });
  });

  group('Case.withAssignee', () {
    test('attaches a name without touching anything else', () {
      final value = buildCase(assigneeId: 'staff-1');
      final joined = value.withAssignee(ada);

      expect(joined.assignee, ada);
      expect(joined.id, value.id);
      expect(joined.status, value.status);
      expect(joined.assigneeId, value.assigneeId);
    });

    test('can clear the name, which copyWith could not express', () {
      final value = buildCase(assignee: ada);
      expect(value.withAssignee(null).assignee, isNull);
    });
  });

  group('CaseFilter.matches', () {
    test('all admits every status', () {
      for (final status in CaseStatus.values) {
        expect(CaseFilter.all.matches(buildCase(status: status)), isTrue);
      }
    });

    test('every other tab admits its own status and nothing else', () {
      for (final filter in CaseFilter.values) {
        final status = filter.status;
        if (status == null) continue;

        expect(
          filter.matches(buildCase(status: status)),
          isTrue,
          reason: filter.name,
        );

        for (final other in CaseStatus.values) {
          if (other == status) continue;
          expect(
            filter.matches(buildCase(status: other)),
            isFalse,
            reason: '${filter.name} must not admit ${other.name}',
          );
        }
      }
    });

    test('there is a tab for every status the app knows', () {
      final tabbed = CaseFilter.values
          .map((filter) => filter.status)
          .nonNulls
          .toSet();
      final known = CaseStatus.values.where((status) => status.isKnown).toSet();
      expect(tabbed, known);
    });

    test('an unknown status falls out of every tab but All', () {
      final value = buildCase(status: CaseStatus.unknown);
      for (final filter in CaseFilter.values) {
        expect(
          filter.matches(value),
          filter == CaseFilter.all,
          reason: filter.name,
        );
      }
    });
  });
}
