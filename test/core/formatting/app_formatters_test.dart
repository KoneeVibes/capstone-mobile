import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/formatting/app_formatters.dart';

void main() {
  group('dates', () {
    final moment = DateTime(2026, 8, 12, 21, 30);

    test('formats date, date-time and time', () {
      expect(AppFormatters.date(moment), '12 Aug 2026');
      expect(AppFormatters.dateTime(moment), '12 Aug 2026, 9:30 PM');
      expect(AppFormatters.time(moment), '9:30 PM');
    });

    test('returns an empty string for a null date', () {
      expect(AppFormatters.date(null), '');
      expect(AppFormatters.dateTime(null), '');
      expect(AppFormatters.time(null), '');
    });

    test('parses the ISO timestamps the API returns', () {
      final parsed = AppFormatters.parseIso('2026-08-12T18:11:45.542Z');
      expect(parsed, isNotNull);
      expect(parsed!.toUtc().year, 2026);
      expect(parsed.toUtc().month, 8);
      expect(parsed.toUtc().day, 12);
    });

    test('returns null rather than throwing on unusable input', () {
      expect(AppFormatters.parseIso(null), isNull);
      expect(AppFormatters.parseIso(''), isNull);
      expect(AppFormatters.parseIso('not a date'), isNull);
      expect(AppFormatters.dateFromIso('not a date'), '');
    });
  });

  group('relative time', () {
    final now = DateTime(2026, 8, 12, 12);

    test('describes recent moments in words', () {
      expect(
        AppFormatters.relative(now.subtract(const Duration(seconds: 20)), now: now),
        'Just now',
      );
      expect(
        AppFormatters.relative(now.subtract(const Duration(minutes: 1)), now: now),
        '1 minute ago',
      );
      expect(
        AppFormatters.relative(now.subtract(const Duration(minutes: 5)), now: now),
        '5 minutes ago',
      );
      expect(
        AppFormatters.relative(now.subtract(const Duration(hours: 1)), now: now),
        '1 hour ago',
      );
      expect(
        AppFormatters.relative(now.subtract(const Duration(hours: 3)), now: now),
        '3 hours ago',
      );
      expect(
        AppFormatters.relative(now.subtract(const Duration(days: 1)), now: now),
        'Yesterday',
      );
      expect(
        AppFormatters.relative(now.subtract(const Duration(days: 3)), now: now),
        '3 days ago',
      );
    });

    test('falls back to a date beyond a week', () {
      expect(
        AppFormatters.relative(now.subtract(const Duration(days: 20)), now: now),
        '23 Jul',
      );
      expect(
        AppFormatters.relative(DateTime(2025, 1, 5), now: now),
        '5 Jan 2025',
      );
    });

    test('handles a future timestamp without producing negative wording', () {
      final result = AppFormatters.relative(
        now.add(const Duration(days: 2)),
        now: now,
      );
      expect(result, '14 Aug 2026');
      expect(result, isNot(contains('-')));
    });

    test('returns an empty string for null', () {
      expect(AppFormatters.relative(null), '');
    });
  });

  group('currency', () {
    test('formats naira amounts', () {
      expect(AppFormatters.currency(12500), '₦12,500.00');
      expect(AppFormatters.currency(0), '₦0.00');
      expect(AppFormatters.currency(1234.5), '₦1,234.50');
    });

    test('treats null as zero', () {
      expect(AppFormatters.currency(null), '₦0.00');
    });

    test('compacts large amounts', () {
      expect(AppFormatters.currencyCompact(12500), '₦12.5K');
    });
  });

  group('phone', () {
    test('groups a local number', () {
      expect(AppFormatters.phone('08034112290'), '0803 411 2290');
    });

    test('normalises international forms to local grouping', () {
      expect(AppFormatters.phone('+2348034112290'), '0803 411 2290');
      expect(AppFormatters.phone('2348034112290'), '0803 411 2290');
    });

    test('re-groups an already spaced number', () {
      expect(AppFormatters.phone('0701 882 4471'), '0701 882 4471');
    });

    test('returns unrecognised input unchanged rather than mangling it', () {
      expect(AppFormatters.phone('  12345 '), '12345');
      expect(AppFormatters.phone('not a number'), 'not a number');
    });

    test('returns an empty string for null or blank', () {
      expect(AppFormatters.phone(null), '');
      expect(AppFormatters.phone('   '), '');
    });
  });

  group('names', () {
    test('builds initials from separate first and last names', () {
      expect(AppFormatters.initials('Ekong', 'Silas'), 'ES');
      expect(AppFormatters.initials('ada', 'okafor'), 'AO');
    });

    test('builds initials from a single full name', () {
      expect(AppFormatters.initials('Ekong Silas'), 'ES');
    });

    test('falls back to the first two letters of a lone name', () {
      expect(AppFormatters.initials('Ada'), 'AD');
      expect(AppFormatters.initials('A'), 'A');
    });

    test('returns an empty string when there is nothing to work with', () {
      expect(AppFormatters.initials(null), '');
      expect(AppFormatters.initials('', ''), '');
      expect(AppFormatters.initials('   '), '');
    });

    test('joins name parts, skipping the missing ones', () {
      expect(AppFormatters.fullName('Ada', 'Grace', 'Okafor'), 'Ada Grace Okafor');
      expect(AppFormatters.fullName('Ada', null, 'Okafor'), 'Ada Okafor');
      expect(AppFormatters.fullName('Ada', '', 'Okafor'), 'Ada Okafor');
      expect(AppFormatters.fullName('Ada'), 'Ada');
    });

    test('title-cases API values such as roles', () {
      expect(AppFormatters.titleCase('manager'), 'Manager');
      expect(AppFormatters.titleCase('ADMIN'), 'Admin');
      expect(AppFormatters.titleCase('legal reviewer'), 'Legal Reviewer');
      expect(AppFormatters.titleCase(null), '');
    });
  });


  group('api label', () {
    test('reads a kebab-cased API value as a phrase', () {
      expect(AppFormatters.apiLabel('due-diligence'), 'Due diligence');
      expect(
        AppFormatters.apiLabel('physical-inspection'),
        'Physical inspection',
      );
      expect(
        AppFormatters.apiLabel('certificate-of-occupancy'),
        'Certificate of occupancy',
      );
      expect(
        AppFormatters.apiLabel('pending-information'),
        'Pending information',
      );
    });

    test('handles snake case and single words too', () {
      expect(AppFormatters.apiLabel('under_review'), 'Under review');
      expect(AppFormatters.apiLabel('building'), 'Building');
      expect(AppFormatters.apiLabel('website'), 'Website');
    });

    test('is sentence case, not title case', () {
      // `Certificate Of Occupancy` would be wrong: these values are phrases,
      // which is why this exists alongside titleCase rather than replacing it.
      expect(
        AppFormatters.apiLabel('right-of-occupancy'),
        isNot('Right Of Occupancy'),
      );
      expect(AppFormatters.apiLabel('DEED-OF-ASSIGNMENT'), 'Deed of assignment');
    });

    test('handles null, blanks and stray separators', () {
      expect(AppFormatters.apiLabel(null), '');
      expect(AppFormatters.apiLabel('   '), '');
      expect(AppFormatters.apiLabel('--'), '');
      expect(AppFormatters.apiLabel('  due--diligence  '), 'Due diligence');
    });
  });

  group('file size', () {
    test('scales through the units', () {
      expect(AppFormatters.fileSize(512), '512 B');
      expect(AppFormatters.fileSize(1024), '1.0 KB');
      expect(AppFormatters.fileSize(1536), '1.5 KB');
      expect(AppFormatters.fileSize(1048576), '1.0 MB');
      expect(AppFormatters.fileSize(1073741824), '1.0 GB');
    });

    test('handles null and non-positive values', () {
      expect(AppFormatters.fileSize(null), '0 B');
      expect(AppFormatters.fileSize(0), '0 B');
      expect(AppFormatters.fileSize(-5), '0 B');
    });
  });
}
