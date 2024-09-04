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
    if (!enabled) {
      return serializer?.fromJson(remoteSnap.data()) ?? remoteSnap.data();
    }

    if (!remoteSnap.exists) {
      localDoc.delete();
      return null;
    } else {
      final data = serializer?.fromJson(remoteSnap.data()) ?? remoteSnap.data();
      final snap = localDoc.createOrUpdate(data);
      onWrite?.call(snap);
      return data;
    }
  }

  bool _beforeWrite<T>(
    RemoteDocumentSnapshot snap,
    Serializer<T>? serializer,
  ) {
    if (!enabled) {
      return false;
    }

    return onBeforeWrite?.call(snap, serializer) ?? true;
  }
}
