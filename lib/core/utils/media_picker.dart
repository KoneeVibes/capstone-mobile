import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_constants.dart';
import '../formatting/app_formatters.dart';
import 'error/app_failure.dart';
import 'error/app_failures.dart';
import 'result.dart';

/// A file the user chose, after validation.
class PickedMedia extends Equatable {
  const PickedMedia({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
    required this.extension,
  });

  /// Absolute path on disk. The data layer turns this into a `MultipartFile`.
  final String path;

  final String fileName;
  final int sizeBytes;

  /// Lower-case, without the leading dot.
  final String extension;

  bool get isImage =>
      AppConstants.allowedImageExtensions.contains(extension);

  /// Human-readable size, e.g. `1.2 MB`.
  String get displaySize => AppFormatters.fileSize(sizeBytes);

  @override
  List<Object?> get props => [path, fileName, sizeBytes, extension];
}

/// The raw plugin calls, isolated so the validation around them is testable
/// without platform channels.
abstract class MediaPickerBackend {
  Future<RawPickedFile?> pickImage();

  Future<List<RawPickedFile>> pickFiles({
    required Set<String> allowedExtensions,
    required bool allowMultiple,
  });
}

/// What a picker plugin hands back, before any checking.
class RawPickedFile {
  const RawPickedFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });

  /// Null when the platform gives no on-disk path.
  final String? path;
  final String name;
  final int sizeBytes;
}

/// Chooses images and documents.
///
/// Every method returns a [Result], matching the repository idiom: `Ok(null)`
/// means the user backed out, `Err` carries an [AppFailure] a screen can render
/// directly. Nothing here ever throws a `PlatformException` at a widget.
///
/// Features depend on this rather than on `image_picker` or `file_picker`, so
/// picking behaves the same everywhere and the plugins stay replaceable.
class MediaPicker {
  const MediaPicker(this._backend);

  final MediaPickerBackend _backend;

  /// Picks a photo from the library, re-encoded and resized on the way out.
  Future<Result<PickedMedia?>> pickImage() => _guard(
    () => _backend.pickImage(),
    allowed: AppConstants.allowedImageExtensions,
    onUnsupported: AppFailures.unsupportedFileType,
  );

  /// Picks a single document.
  Future<Result<PickedMedia?>> pickDocument({
    Set<String>? allowedExtensions,
  }) {
    final allowed =
        allowedExtensions ?? AppConstants.allowedDocumentExtensions;
    return _guard(
      () async {
        final files = await _backend.pickFiles(
          allowedExtensions: allowed,
          allowMultiple: false,
        );
        return files.isEmpty ? null : files.first;
      },
      allowed: allowed,
      onUnsupported: AppFailures.unsupportedDocumentType,
    );
  }

  /// Picks either an image or a document in one step.
  Future<Result<PickedMedia?>> pickImageOrDocument() => pickDocument();

  /// Picks several documents at once.
  ///
  /// Returns `Ok([])` when the user backs out. The first invalid file fails the
  /// whole batch, so a partially-valid selection is never silently trimmed.
  Future<Result<List<PickedMedia>>> pickDocuments({
    Set<String>? allowedExtensions,
    int? limit,
  }) async {
    final allowed =
        allowedExtensions ?? AppConstants.allowedDocumentExtensions;

    final List<RawPickedFile> raw;
    try {
      raw = await _backend.pickFiles(
        allowedExtensions: allowed,
        allowMultiple: true,
      );
    } on Object catch (error, stackTrace) {
      return Err(_pluginFailure(error, stackTrace));
    }

    if (raw.isEmpty) return const Ok([]);

    final capped = limit != null && raw.length > limit
        ? raw.take(limit).toList()
        : raw;

    final picked = <PickedMedia>[];
    for (final file in capped) {
      final validated = _validate(
        file,
        allowed: allowed,
        onUnsupported: AppFailures.unsupportedDocumentType,
      );
      if (validated.isErr) return Err(validated.failureOrNull!);
      picked.add(validated.valueOrNull!);
    }

    return Ok(picked);
  }

  /// Runs [pick], converting a cancel into `Ok(null)`, a plugin throw into an
  /// [AppFailure], and validating anything that comes back.
  Future<Result<PickedMedia?>> _guard(
    Future<RawPickedFile?> Function() pick, {
    required Set<String> allowed,
    required AppFailure onUnsupported,
  }) async {
    final RawPickedFile? raw;
    try {
      raw = await pick();
    } on Object catch (error, stackTrace) {
      return Err(_pluginFailure(error, stackTrace));
    }

    // The user dismissed the picker. Not a failure.
    if (raw == null) return const Ok(null);

    final validated = _validate(
      raw,
      allowed: allowed,
      onUnsupported: onUnsupported,
    );
    return validated.fold(
      onOk: Ok<PickedMedia?>.new,
      onErr: Err<PickedMedia?>.new,
    );
  }

  Result<PickedMedia> _validate(
    RawPickedFile raw, {
    required Set<String> allowed,
    required AppFailure onUnsupported,
  }) {
    final path = raw.path;
    if (path == null || path.isEmpty) {
      return const Err(AppFailures.fileUnreadable);
    }

    if (raw.sizeBytes > AppConstants.maxUploadBytes) {
      return const Err(AppFailures.fileTooLarge);
    }

    final extension = _extensionOf(raw.name.isNotEmpty ? raw.name : path);
    if (!allowed.contains(extension)) return Err(onUnsupported);

    return Ok(
      PickedMedia(
        path: path,
        fileName: raw.name.isNotEmpty ? raw.name : path.split('/').last,
        sizeBytes: raw.sizeBytes,
        extension: extension,
      ),
    );
  }

  /// Lower-case extension without the dot, or an empty string when there is
  /// none — which then fails the allow-list check.
  static String _extensionOf(String nameOrPath) {
    final dot = nameOrPath.lastIndexOf('.');
    if (dot == -1 || dot == nameOrPath.length - 1) return '';
    return nameOrPath.substring(dot + 1).toLowerCase();
  }

  /// Keeps the plugin's own message in debug logs while handing the UI copy it
  /// can actually show.
  static AppFailure _pluginFailure(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('MediaPicker failed: $error');
    }
    return AppFailures.mediaPickFailed;
  }
}

/// Production backend, wrapping `image_picker` and `file_picker`.
class PluginMediaPickerBackend implements MediaPickerBackend {
  PluginMediaPickerBackend({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<RawPickedFile?> pickImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: AppConstants.maxImageDimension,
      maxHeight: AppConstants.maxImageDimension,
      imageQuality: AppConstants.pickedImageQuality,
    );
    if (file == null) return null;

    return RawPickedFile(
      path: file.path,
      name: file.name,
      sizeBytes: await file.length(),
    );
  }

  @override
  Future<List<RawPickedFile>> pickFiles({
    required Set<String> allowedExtensions,
    required bool allowMultiple,
  }) async {
    // file_picker 11 exposes pickFiles as a static; the `.platform` accessor
    // from earlier versions no longer exists.
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions.toList(),
      allowMultiple: allowMultiple,
    );
    if (result == null) return const [];

    return result.files
        .map(
          (file) => RawPickedFile(
            path: file.path,
            name: file.name,
            sizeBytes: file.size,
          ),
        )
        .toList();
  }
}

/// Override this in tests to pick without touching platform channels.
final mediaPickerProvider = Provider<MediaPicker>(
  (ref) => MediaPicker(PluginMediaPickerBackend()),
);
