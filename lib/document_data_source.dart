part of loon_extension_firestore;

class DocumentDataSource<T> {
  late final LocalDocument<T> local;
  late final RemoteDocument<T> remote;

  DocumentDataSource({
    required LoonDocument<T> local,
    required FirestoreDocument<T> remote,
    Serializer<T>? serializer,
  }) {
    this.local = LocalDocument<T>(
      local.parent,
      local.id,
      fromJson: serializer?.fromJson,
      toJson: serializer?.toJson,
      persistorSettings: local.persistorSettings,
      dependenciesBuilder: local.dependenciesBuilder,
    );

    this.remote = RemoteDocument<T>(
      local: this.local,
      serializer: serializer,
      remote: serializer != null
          ? remote.withConverter<T>(
              fromFirestore: (snap, _) {
                return serializer.fromJson({
                  "id": snap.id,
                  ...snap.data()!,
                });
              },
              toFirestore: (item, _) => serializer.toJson(item),
            )
          : remote,
    );
  }

  CollectionDataSource<S> subcollection<S>(
    String id, {
    Serializer<S>? serializer,
    loon.PersistorSettings? persistorSettings,
    loon.DependenciesBuilder<S>? dependenciesBuilder,
  }) {
    return CollectionDataSource<S>(
      local: local.subcollection(
        id,
        persistorSettings: persistorSettings,
        dependenciesBuilder: dependenciesBuilder,
      ),
      remote: remote._remote.collection(id),
      serializer: serializer,
    );
  }
}

class RemoteDocument<T> {
  late final LoonDocument<T> _local;
  late final FirestoreDocument<T> _remote;
  final Serializer<T>? serializer;

  RemoteDocument({
    required LocalDocument<T> local,
    required FirestoreDocument<T> remote,
    this.serializer,
  }) {
    _local = local;
    _remote = remote;
  }

  firestore.DocumentReference<T> get ref {
    return _remote;
  }

  String get id {
    return _remote.id;
  }

  Future<void> create(T data) {
    return _local.optimisticCreate(data, _remote.set(data));
  }

  Future<void> createOrUpdate(T data) {
    if (_local.exists()) {
      return update(data);
    }
    return create(data);
  }

  Future<void> update(
    T data, {
    Set<String> fields = const {},
  }) {
    return _local.optimisticUpdate(
      data,
      Future.sync(
        () {
          final json = serializer?.toJson.call(data) ?? data as loon.Json;
          if (fields.isNotEmpty) {
            return _remote.update(json.pick({...fields}));
          } else {
            return _remote.update(json);
          }
        },
      ),
    );
  }

  Future<void> modify(
    T Function(T? data) modify, {
    Set<String> fields = const {},
  }) {
    final data = modify(_local.get()?.data);
    return update(data, fields: fields);
  }

  Future<T?> get() async {
    final snap = await _remote.get();
    final data = snap.data();
    LoonExtensionFirestore.instance._onWrite(_local, data);
    return data;
  }

  Stream<T?> stream() {
    return _remote.snapshots().map((snap) {
      final data = snap.data();
      LoonExtensionFirestore.instance._onWrite(_local, data);
      return data;
    });
  }
}
