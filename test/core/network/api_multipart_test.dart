import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/network/api_multipart.dart';
import 'package:propertyintelmobileapp/core/utils/media_picker.dart';

void main() {
  PickedMedia picked(String extension) => PickedMedia(
    path: '/x/file.$extension',
    fileName: 'file.$extension',
    sizeBytes: 1,
    extension: extension,
  );

  test('types a part by its checked extension', () {
    expect(
      ApiMultipart.contentTypeOf(picked('pdf')).mimeType,
      'application/pdf',
    );
    expect(ApiMultipart.contentTypeOf(picked('png')).mimeType, 'image/png');
    expect(ApiMultipart.contentTypeOf(picked('jpg')).mimeType, 'image/jpeg');
    expect(ApiMultipart.contentTypeOf(picked('jpeg')).mimeType, 'image/jpeg');
  });
}
