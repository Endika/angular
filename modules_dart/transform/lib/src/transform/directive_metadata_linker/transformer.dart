library angular2.transform.directive_metadata_linker.transformer;

import 'dart:async';
import 'dart:convert';

import 'package:angular2/src/transform/common/asset_reader.dart';
import 'package:angular2/src/transform/common/logging.dart' as log;
import 'package:angular2/src/transform/common/names.dart';
import 'package:barback/barback.dart';

import 'ng_meta_linker.dart';

/// Transformer responsible for processing .ng_summary.json files created by
/// {@link DirectiveProcessor} and "linking" them.
///
/// This step ensures that for libraries that export, all `Directive`s reachable
/// from that library are declared in its associated .ng_meta.json file.
///
/// Said another way, after this step there should be an entry in this `NgMeta`
/// object for all `Directives` visible from its associated `.dart` file.
///
/// This step also ensures that, if `a.dart` imports `b.dart`, `a.ng_deps.dart`
/// imports `b.ng_deps.dart` (if it exists) and we note that this is a
/// ngDeps dependency, ensuring that a's `initReflector` function calls b's
/// `initReflector' function.
///
/// See `common/ng_meta.dart` for the JSON format of these files are serialized
/// to.
///
/// This transformer is part of a multi-phase transform.
/// See `angular2/src/transform/transformer.dart` for transformer ordering.
class DirectiveMetadataLinker extends Transformer {
  final _encoder = const JsonEncoder.withIndent('  ');

  @override
  bool isPrimary(AssetId id) => id.path.endsWith(SUMMARY_META_EXTENSION);

  @override
  Future apply(Transform transform) {
    return log.initZoned(transform, () {
      var primaryId = transform.primaryInput.id;

      return linkDirectiveMetadata(
          new AssetReader.fromTransform(transform), primaryId).then((ngMeta) {
        if (ngMeta != null) {
          final outputId = _ngLinkedAssetId(primaryId);
          if (!ngMeta.isEmpty) {
            transform.addOutput(new Asset.fromString(
                outputId, _encoder.convert(ngMeta.toJson())));
          } else {
            // Not outputting an asset could confuse barback.
            transform.addOutput(new Asset.fromString(outputId, ''));
          }
        }
      });
    });
  }
}

AssetId _ngLinkedAssetId(AssetId primaryInputId) {
  return new AssetId(
      primaryInputId.package, toMetaExtension(primaryInputId.path));
}
