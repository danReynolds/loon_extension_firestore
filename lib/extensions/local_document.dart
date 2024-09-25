part of loon_extension_firestore;

extension DocumentExtensions<T> on LoonDocument<T> {
  /// Optimistically writes the document with then given data. If the provided future
  /// throws an exception, then the update is rolled back.
  Future<S> optimisticUpdate<S>(T data, Future<S> future) async {
    if (!LoonExtensionFirestore.instance.enabled) {
      return future;
    }

    final existingValue = get()!.data;
    try {
      update(data);
      return await future;
    } catch (e) {
      update(existingValue);
      rethrow;
    }
  }

  Future<S> optimisticCreate<S>(T data, Future<S> future) async {
    if (!LoonExtensionFirestore.instance.enabled) {
      return future;
    }

    try {
      create(data);
      return await future;
    } catch (e) {
      delete();
      rethrow;
    }
  }

  Future<S> optimisticCreateOrUpdate<S>(T data, Future<S> future) {
    if (exists()) {
      return optimisticUpdate(data, future);
    }
    return optimisticCreate(data, future);
  }

  Future<void> optimisticDelete(Future future) async {
    final prevData = get()?.data;

    try {
      delete();
      await future;
    } catch (e) {
      if (prevData != null) {
        createOrUpdate(prevData);
      }
      rethrow;
    }
  }
}
