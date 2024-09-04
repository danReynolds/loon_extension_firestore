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
  bool Function(
    LocalDocument doc,
    RemoteDocumentSnapshot snap,
    Serializer? serializer,
  )? onBeforeWrite;
  void Function(LocalDocumentSnapshot snap)? onWrite;

  LoonExtensionFirestore._();

  static LoonExtensionFirestore instance = LoonExtensionFirestore._();

  static configure({
    bool enabled = false,
    void Function(LocalDocumentSnapshot snap)? onWrite,
    bool Function(
      LocalDocument doc,
      RemoteDocumentSnapshot snap,
      Serializer? serializer,
    )? onBeforeWrite,
  }) {
    instance.enabled = enabled;
    instance.onWrite = onWrite;
    instance.onBeforeWrite = onBeforeWrite;

    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      final remote = firestore.FirebaseFirestore.instance;
      remote.settings = remote.settings.copyWith(persistenceEnabled: !enabled);
    }
  }

  T? _write<T>(
    LocalDocument<T> localDoc,
    RemoteDocumentSnapshot remoteSnap,
    Serializer<T>? serializer,
  ) {
    final exists = remoteSnap.exists;
    final data = exists
        ? serializer?.fromJson(remoteSnap.data()) ?? remoteSnap.data()
        : null;

    if (!enabled) {
      return data;
    }

    if (!exists) {
      localDoc.delete();
      onWrite?.call(LocalDocumentSnapshot(doc: localDoc, data: null));
    } else {
      final snap = localDoc.createOrUpdate(data);
      onWrite?.call(snap);
    }

    return data;
  }

  bool _beforeWrite<T>(
    LocalDocument<T> doc,
    RemoteDocumentSnapshot snap,
    Serializer<T>? serializer,
  ) {
    if (!enabled) {
      return false;
    }

    return onBeforeWrite?.call(doc, snap, serializer) ?? true;
  }
}
