part of loon_extension_firestore;

class DocumentDataSource<T> {
  late final LocalDocument<T> local;
  late final RemoteDocument<T> remote;

  DocumentDataSource({
    required LoonDocument<T> local,
    required FirestoreDocument remote,
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
      remote: remote,
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
  late final FirestoreDocument _remote;
  final Serializer<T>? serializer;

  RemoteDocument({
    required LocalDocument<T> local,
    required FirestoreDocument remote,
    this.serializer,
  }) {
    _local = local;
    _remote = remote;
  }

  T? _writeSnap(RemoteDocumentSnapshot remoteSnap) {
    final shouldWrite = LoonExtensionFirestore.instance._beforeWrite(
      _local,
      remoteSnap,
      serializer,
    );

    if (shouldWrite) {
      return LoonExtensionFirestore.instance._write(
        _local,
        remoteSnap,
        serializer,
      );
    }

    return null;
  }

  firestore.DocumentReference get ref {
    return _remote;
  }

  String get id {
    return _remote.id;
  }

  String get path {
    return _remote.path;
  }

  RemoteCollection<T> collection(String id) {
    return RemoteCollection<T>(
      serializer: serializer,
      local: _local.subcollection(id),
      remote: _remote.collection(id),
    );
  }

  Future<void> delete({
    bool optimistic = true,
  }) async {
    final future = _remote.delete();
    if (optimistic) {
      return _local.optimisticDelete(future);
    }
    return future;
  }

  Future<void> create(
    T data, {
    bool optimistic = true,
  }) {
    final future = _remote.set(serializer?.toJson(data) ?? data);
    if (optimistic) {
      return _local.optimisticCreate(data, future);
    }
    return future;
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
    bool optimistic = true,
  }) {
    final json = serializer?.toJson.call(data) ?? data as loon.Json;
    final pickedJson = fields.isNotEmpty ? json.pick({...fields}) : json;
    final future = _remote.update(pickedJson);

    if (optimistic) {
      return _local.optimisticUpdate(data, future);
    }

    return future;
  }

  Future<void> modify(
    T Function(T? data) modify, {
    Set<String> fields = const {},
  }) {
    final data = modify(_local.get()?.data);
    return update(data, fields: fields);
  }

  Future<T?> get() async {
    return _writeSnap(
      await _remote.get(
        const GetOptions(source: Source.server),
      ),
    );
  }

  Stream<T?> stream() {
    return _remote
        .snapshots(includeMetadataChanges: true)
        // Filter out cached events, since the Loon cache is used instead of the Firestore cache
        // and only server updates should be returned.
        .where((snap) => !snap.metadata.isFromCache)
        .map((snap) => _writeSnap(snap));
  }
}
