library loon_extension_firestore;

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:loon/loon.dart' as loon;
import 'dart:io';
part 'collection_data_source.dart';
part 'document_data_source.dart';
part 'types.dart';
part 'extensions/local_document.dart';
part 'extensions/map.dart';
part 'serializer.dart';

class LoonExtensionFirestore {
  bool enabled = false;
  void Function(LocalDocumentSnapshot snap)? onWrite;

  LoonExtensionFirestore._();

  static LoonExtensionFirestore instance = LoonExtensionFirestore._();

  static configure({
    bool enabled = false,
    void Function(LocalDocumentSnapshot snap)? onWrite,
  }) {
    instance.enabled = enabled;
    instance.onWrite = onWrite;

    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      final remote = firestore.FirebaseFirestore.instance;
      remote.settings = remote.settings.copyWith(
        persistenceEnabled: !enabled,
      );
    }
  }

  void _onWrite<T>(LocalDocument<T> doc, T? data) {
    if (!enabled) {
      return;
    }

    if (data == null) {
      doc.delete();
    } else {
      final snap = doc.createOrUpdate(data);
      onWrite?.call(snap);
    }
  }
}
