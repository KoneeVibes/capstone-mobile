import 'package:flutter/services.dart';

import '../../../core/utils/error/error_handler.dart';
import '../../../core/utils/result.dart';
import '../domain/legal_document.dart';

/// Reads a legal page's markdown from the app bundle.
class LegalRepository {
  const LegalRepository(this._bundle);

  final AssetBundle _bundle;

  Future<Result<String>> read(LegalDocument document) async {
    try {
      return Ok(await _bundle.loadString(document.asset));
    } on Object catch (error, stackTrace) {
      return Err(ErrorHandler.from(error, stackTrace));
    }
  }
}
