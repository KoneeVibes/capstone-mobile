import 'package:dio/dio.dart';

import '../utils/media_picker.dart';

/// Picked files as multipart parts, for every feature that uploads.
abstract final class ApiMultipart {
  const ApiMultipart._();

  /// The picker already checked the extension, so the content type follows
  /// it rather than dio's guess from the path.
  static DioMediaType contentTypeOf(PickedMedia file) =>
      switch (file.extension) {
        'pdf' => DioMediaType('application', 'pdf'),
        'png' => DioMediaType('image', 'png'),
        _ => DioMediaType('image', 'jpeg'),
      };

  static Future<MultipartFile> fileOf(PickedMedia file) =>
      MultipartFile.fromFile(
        file.path,
        filename: file.fileName,
        contentType: contentTypeOf(file),
      );
}
