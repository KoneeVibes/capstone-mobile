import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/utils/media_picker.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/widgets/case_report_sheet.dart';

PickedMedia _file(String name) => PickedMedia(
  path: '/tmp/$name',
  fileName: name,
  sizeBytes: 1024,
  extension: name.split('.').last,
);

void main() {
  group('mergeReportFiles', () {
    test('appends new files after the current ones', () {
      final merged = mergeReportFiles([_file('a.pdf')], [_file('b.png')]);

      expect(merged.map((file) => file.fileName), ['a.pdf', 'b.png']);
    });

    test('skips a file already chosen', () {
      final merged = mergeReportFiles(
        [_file('a.pdf')],
        [_file('a.pdf'), _file('c.jpg')],
      );

      expect(merged.map((file) => file.fileName), ['a.pdf', 'c.jpg']);
    });
  });

  test('a report carries at most three files', () {
    expect(CaseReportSheet.maxFiles, 3);
  });
}
