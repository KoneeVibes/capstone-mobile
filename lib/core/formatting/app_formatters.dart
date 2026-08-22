import 'package:intl/intl.dart';

/// Presentation formatting for dates, money, phone numbers and names.
///
/// Every value that reaches a widget already formatted goes through here, so a
/// date or an amount looks the same on every screen.
abstract final class AppFormatters {
  const AppFormatters._();

  static final DateFormat _date = DateFormat('d MMM yyyy');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, h:mm a');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _dayMonth = DateFormat('d MMM');

  static final NumberFormat _naira = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );
  static final NumberFormat _nairaCompact = NumberFormat.compactCurrency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 1,
  );

  /// `12 Aug 2026`
  static String date(DateTime? value) =>
      value == null ? '' : _date.format(value.toLocal());

  /// `12 Aug 2026, 9:30 PM`
  static String dateTime(DateTime? value) =>
      value == null ? '' : _dateTime.format(value.toLocal());

  /// `9:30 PM`
  static String time(DateTime? value) =>
      value == null ? '' : _time.format(value.toLocal());

  /// Parses an ISO-8601 string from the API, returning null when absent or
  /// malformed rather than throwing.
  static DateTime? parseIso(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Formats an ISO-8601 string straight to display form.
  static String dateFromIso(String? value) => date(parseIso(value));

  /// Human-relative time, falling back to an absolute date beyond a week.
  ///
  /// [now] is injectable so the behaviour is testable without clock tricks.
  static String relative(DateTime? value, {DateTime? now}) {
    if (value == null) return '';

    final reference = now ?? DateTime.now();
    final local = value.toLocal();
    final difference = reference.difference(local);

    if (difference.isNegative) return date(local);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${_plural(difference.inMinutes, 'minute')} ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} ${_plural(difference.inHours, 'hour')} ago';
    }
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (reference.year == local.year) return _dayMonth.format(local);
    return date(local);
  }

  /// `₦12,500.00`
  static String currency(num? value) => _naira.format(value ?? 0);

  /// `₦12.5K` — for tiles and summaries where space is tight.
  static String currencyCompact(num? value) => _nairaCompact.format(value ?? 0);

  /// `0803 411 2290`, accepting local or `+234` input.
  ///
  /// Anything that is not a recognisable Nigerian number is returned trimmed
  /// but otherwise untouched, so bad data still displays.
  static String phone(String? value) {
    if (value == null || value.trim().isEmpty) return '';

    final digits = value.replaceAll(RegExp(r'[^\d+]'), '');
    var local = digits;

    if (local.startsWith('+234')) {
      local = '0${local.substring(4)}';
    } else if (local.startsWith('234') && local.length == 13) {
      local = '0${local.substring(3)}';
    }

    if (local.length != 11 || !local.startsWith('0')) return value.trim();

    return '${local.substring(0, 4)} ${local.substring(4, 7)} '
        '${local.substring(7)}';
  }

  /// Two-letter initials for an avatar tile, e.g. `Ekong Silas` -> `ES`.
  ///
  /// Falls back to the first two letters of a single name, and to an empty
  /// string when there is nothing usable.
  static String initials(String? first, [String? last]) {
    final firstPart = first?.trim() ?? '';
    final lastPart = last?.trim() ?? '';

    if (firstPart.isEmpty && lastPart.isEmpty) return '';

    if (lastPart.isNotEmpty && firstPart.isNotEmpty) {
      return '${firstPart[0]}${lastPart[0]}'.toUpperCase();
    }

    final single = firstPart.isNotEmpty ? firstPart : lastPart;
    final words = single.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);

    if (words.length >= 2) {
      return '${words.first[0]}${words.elementAt(1)[0]}'.toUpperCase();
    }
    return single.substring(0, single.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Joins name parts, skipping any that are missing.
  static String fullName(String? first, [String? middle, String? last]) => [
    first?.trim(),
    middle?.trim(),
    last?.trim(),
  ].where((part) => part != null && part.isNotEmpty).join(' ');

  /// `ada okafor` -> `Ada Okafor`. Used for API values such as role names.
  static String titleCase(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.length == 1
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  /// `due-diligence` -> `Due diligence`. For kebab- and snake-cased API values.
  ///
  /// Sentence case rather than [titleCase]'s per-word capitals, because these
  /// values are phrases: `certificate-of-occupancy` has to read as `Certificate
  /// of occupancy`, not `Certificate Of Occupancy`.
  static String apiLabel(String? value) {
    final words = (value ?? '')
        .trim()
        .split(RegExp(r'[\s_-]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';

    final first = words.first.toLowerCase();
    return [
      first.length == 1
          ? first.toUpperCase()
          : '${first[0].toUpperCase()}${first.substring(1)}',
      ...words.skip(1).map((word) => word.toLowerCase()),
    ].join(' ');
  }

  /// `1.2 MB`
  static String fileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';

    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;

    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }

    final rounded = unit == 0
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(1);
    return '$rounded ${units[unit]}';
  }

  static String _plural(int count, String word) =>
      count == 1 ? word : '${word}s';
}
