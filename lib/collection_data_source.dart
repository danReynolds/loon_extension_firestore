part of loon_extension_firestore;

class CollectionDataSource<T> {
  late final LocalCollection<T> local;
  late final RemoteCollection<T> remote;
  Serializer<T>? serializer;

  CollectionDataSource({
    required LoonCollection<T> local,
    required FirestoreCollection remote,
    this.serializer,
  }) {
    this.local = LocalCollection<T>(
      local.parent,
      local.name,
      fromJson: serializer?.fromJson,
      toJson: serializer?.toJson,
      dependenciesBuilder: local.dependenciesBuilder,
      persistorSettings: local.persistorSettings,
    );
    this.remote = RemoteCollection<T>(
      serializer: serializer,
      local: this.local,
      remote: remote,
    );
  }

  DocumentDataSource<T> doc(String id) {
    return DocumentDataSource<T>(
      local: local.doc(id),
      remote: remote.ref.doc(id),
      serializer: serializer,
    );
  }
}

class RemoteCollection<T> {
  final LoonCollection<T> _local;
  final FirestoreCollection _remote;
  final Serializer<T>? serializer;

  RemoteCollection({
    this.serializer,
    required LocalCollection<T> local,
    required FirestoreCollection remote,
  })  : _local = local,
        _remote = remote;

  RemoteQuery<T> toQuery() {
    return RemoteQuery<T>(
      path: _remote.path,
      serializer: serializer,
      local: _local,
      remote: _remote,
    );
  }

  FirestoreCollection get ref {
    return _remote;
  }

  RemoteQuery<T> where(
    Object? fieldOrFilter, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    if (fieldOrFilter == null) {
      return toQuery();
    }

    return toQuery().where(
      fieldOrFilter,
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      arrayContains: arrayContains,
      arrayContainsAny: arrayContainsAny,
      whereIn: whereIn,
      whereNotIn: whereNotIn,
      isNull: isNull,
    );
  }

  RemoteQuery<T> limit(int amount) {
    return toQuery().limit(amount);
  }

  RemoteQuery<T> orderBy(
    String field, {
    bool descending = false,
  }) {
    return toQuery().orderBy(field, descending: descending);
  }

  RemoteDocument<T> doc([String? id]) {
    final docId = id ?? _remote.doc().id;
    return DocumentDataSource<T>(
      serializer: serializer,
      local: _local.doc(docId),
      remote: _remote.doc(docId),
    ).remote;
  }

  Future<List<T>> get({
    bool cache = true,
    bool replace = false,
  }) async {
    return toQuery().get();
  }

  Stream<List<T>> stream() {
    return RemoteQuery<T>(
      path: _remote.path,
      serializer: serializer,
      local: _local,
      remote: _remote,
    ).stream();
  }
}

class RemoteQuery<T> {
  late final LocalCollection<T> _local;
  late final FirestoreQuery _remote;
  final Serializer<T>? serializer;
  final String path;

  RemoteQuery({
    required this.serializer,
    required this.path,
    required LoonCollection<T> local,
    required FirestoreQuery remote,
  }) {
    _local = local;
    _remote = remote;
  }

  FirestoreQuery get ref {
    return _remote;
  }

  List<T> _writeSnaps(List<firestore.QueryDocumentSnapshot> snaps) {
    return snaps
        .map(
          (remoteSnap) {
            final shouldWrite = LoonExtensionFirestore.instance._beforeWrite(
              _local.doc(remoteSnap.id),
              remoteSnap,
              serializer,
            );

            if (shouldWrite) {
              return LoonExtensionFirestore.instance._write(
                _local.doc(remoteSnap.id),
                remoteSnap,
                serializer,
              );
            }

            return null;
          },
        )
        .whereType<T>()
        .toList();
  }

  RemoteQuery<T> where(
    Object? fieldOrFilter, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    if (fieldOrFilter == null) {
      return this;
    }

    return RemoteQuery<T>(
      path: path,
      serializer: serializer,
      local: _local,
      remote: _remote.where(
        fieldOrFilter,
        isEqualTo: isEqualTo,
        isNotEqualTo: isNotEqualTo,
        isLessThan: isLessThan,
        isLessThanOrEqualTo: isLessThanOrEqualTo,
        isGreaterThan: isGreaterThan,
        isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        arrayContains: arrayContains,
        arrayContainsAny: arrayContainsAny,
        whereIn: whereIn,
        whereNotIn: whereNotIn,
        isNull: isNull,
      ),
    );
  }

  RemoteQuery<T> limit(int amount) {
    return RemoteQuery<T>(
      path: path,
      serializer: serializer,
      local: _local,
      remote: _remote.limit(amount),
    );
  }

  RemoteQuery<T> orderBy(
    String field, {
    bool descending = false,
  }) {
    return RemoteQuery<T>(
      path: path,
      serializer: serializer,
      local: _local,
      remote: _remote.orderBy(field, descending: descending),
    );
  }

  Future<List<T>> get() async {
    final snap = await _remote.get();
    return _writeSnaps(snap.docs);
  }

  Stream<List<T>> stream() {
    return _remote.snapshots().map((snap) => _writeSnaps(snap.docs));
  }
}
