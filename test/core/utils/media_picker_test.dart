import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/constants/app_constants.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failures.dart';
import 'package:propertyintelmobileapp/core/utils/media_picker.dart';

/// Stands in for the plugins so validation is exercised without platform
/// channels.
class FakeBackend implements MediaPickerBackend {
  FakeBackend({this.image, this.files = const [], this.throws});

  RawPickedFile? image;
  List<RawPickedFile> files;
  Object? throws;

  Set<String>? lastAllowedExtensions;
  bool? lastAllowMultiple;

  @override
  Future<RawPickedFile?> pickImage() async {
    if (throws != null) throw throws!;
    return image;
  }

  @override
  Future<List<RawPickedFile>> pickFiles({
    required Set<String> allowedExtensions,
    required bool allowMultiple,
  }) async {
    if (throws != null) throw throws!;
    lastAllowedExtensions = allowedExtensions;
    lastAllowMultiple = allowMultiple;
    return files;
  }
}

RawPickedFile _file({
  String? path = '/tmp/photo.jpg',
  String name = 'photo.jpg',
  int sizeBytes = 2048,
}) => RawPickedFile(path: path, name: name, sizeBytes: sizeBytes);

void main() {
  late FakeBackend backend;
  late MediaPicker picker;

  setUp(() {
    backend = FakeBackend();
    picker = MediaPicker(backend);
  });

  group('pickImage', () {
    test('returns the picked file when it is valid', () async {
      backend.image = _file();

      final result = await picker.pickImage();
      final picked = result.valueOrNull;

      expect(result.isOk, isTrue);
      expect(picked, isNotNull);
      expect(picked!.path, '/tmp/photo.jpg');
      expect(picked.fileName, 'photo.jpg');
      expect(picked.extension, 'jpg');
      expect(picked.isImage, isTrue);
      expect(picked.displaySize, '2.0 KB');
    });

    test('treats a dismissed picker as success with no file', () async {
      backend.image = null;

      final result = await picker.pickImage();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('lower-cases the extension so PNG and png both pass', () async {
      backend.image = _file(path: '/tmp/Shot.PNG', name: 'Shot.PNG');

      final result = await picker.pickImage();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.extension, 'png');
    });

    test('rejects a format the API does not accept', () async {
      backend.image = _file(path: '/tmp/photo.heic', name: 'photo.heic');

      final result = await picker.pickImage();

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, AppFailures.unsupportedFileType);
    });

    test('rejects a file with no extension at all', () async {
      backend.image = _file(path: '/tmp/photo', name: 'photo');

      expect((await picker.pickImage()).isErr, isTrue);
    });

    test('rejects a file over the upload limit', () async {
      backend.image = _file(sizeBytes: AppConstants.maxUploadBytes + 1);

      final result = await picker.pickImage();

      expect(result.failureOrNull, AppFailures.fileTooLarge);
    });

    test('accepts a file exactly at the limit', () async {
      backend.image = _file(sizeBytes: AppConstants.maxUploadBytes);

      expect((await picker.pickImage()).isOk, isTrue);
    });

    test('rejects an entry the platform gave no path for', () async {
      backend.image = _file(path: null);

      expect(
        (await picker.pickImage()).failureOrNull,
        AppFailures.fileUnreadable,
      );
    });

    test('converts a plugin throw into a safe failure', () async {
      backend.throws = Exception('MissingPluginException: no implementation');

      final result = await picker.pickImage();
      final failure = result.failureOrNull;

      expect(failure, AppFailures.mediaPickFailed);
      expect(failure!.message.toLowerCase(), isNot(contains('exception')));
      expect(failure.message.toLowerCase(), isNot(contains('plugin')));
    });
  });

  group('pickDocument', () {
    test('asks the backend for the document extensions, one file', () async {
      backend.files = [_file(path: '/tmp/deed.pdf', name: 'deed.pdf')];

      final result = await picker.pickDocument();

      expect(result.valueOrNull!.extension, 'pdf');
      expect(result.valueOrNull!.isImage, isFalse);
      expect(
        backend.lastAllowedExtensions,
        AppConstants.allowedDocumentExtensions,
      );
      expect(backend.lastAllowMultiple, isFalse);
    });

    test('honours a caller-supplied allow-list', () async {
      backend.files = [_file(path: '/tmp/deed.pdf', name: 'deed.pdf')];

      await picker.pickDocument(allowedExtensions: const {'pdf'});

      expect(backend.lastAllowedExtensions, {'pdf'});
    });

    test('rejects a document outside the allow-list', () async {
      backend.files = [_file(path: '/tmp/app.exe', name: 'app.exe')];

      expect(
        (await picker.pickDocument()).failureOrNull,
        AppFailures.unsupportedDocumentType,
      );
    });

    test('treats an empty selection as a dismissal', () async {
      backend.files = const [];

      final result = await picker.pickDocument();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });
  });

  group('pickDocuments', () {
    test('returns every valid file', () async {
      backend.files = [
        _file(path: '/tmp/a.pdf', name: 'a.pdf'),
        _file(path: '/tmp/b.png', name: 'b.png'),
      ];

      final result = await picker.pickDocuments();

      expect(result.valueOrNull, hasLength(2));
      expect(backend.lastAllowMultiple, isTrue);
    });

    test('fails the whole batch when one file is invalid', () async {
      // Silently dropping the bad one would leave the user wondering why a
      // file they chose never appeared.
      backend.files = [
        _file(path: '/tmp/a.pdf', name: 'a.pdf'),
        _file(path: '/tmp/b.exe', name: 'b.exe'),
      ];

      final result = await picker.pickDocuments();

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, AppFailures.unsupportedDocumentType);
    });

    test('caps the selection at the given limit', () async {
      backend.files = [
        _file(path: '/tmp/a.pdf', name: 'a.pdf'),
        _file(path: '/tmp/b.pdf', name: 'b.pdf'),
        _file(path: '/tmp/c.pdf', name: 'c.pdf'),
      ];

      final result = await picker.pickDocuments(limit: 2);

      expect(result.valueOrNull, hasLength(2));
    });

    test('returns an empty list when nothing was chosen', () async {
      backend.files = const [];

      final result = await picker.pickDocuments();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('converts a plugin throw into a safe failure', () async {
      backend.throws = Exception('boom');

      final result = await picker.pickDocuments();

      expect(result.failureOrNull, AppFailures.mediaPickFailed);
    });
  });

  group('PickedMedia', () {
    test('reports image-ness from the extension', () {
      const image = PickedMedia(
        path: '/tmp/a.png',
        fileName: 'a.png',
        sizeBytes: 10,
        extension: 'png',
      );
      const document = PickedMedia(
        path: '/tmp/a.pdf',
        fileName: 'a.pdf',
        sizeBytes: 10,
        extension: 'pdf',
      );

      expect(image.isImage, isTrue);
      expect(document.isImage, isFalse);
    });

    test('formats its size for display', () {
      const media = PickedMedia(
        path: '/tmp/a.png',
        fileName: 'a.png',
        sizeBytes: 1536 * 1024,
        extension: 'png',
      );

      expect(media.displaySize, '1.5 MB');
    });
  });
}
