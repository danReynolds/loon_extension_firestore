part of loon_extension_firestore;

extension DocumentExtensions<T> on LoonDocument<T> {
  /// Optimistically writes the document with then given data. If the provided future
  /// throws an exception, then the update is rolled back.
  Future<void> optimisticUpdate(
    T data,
    Future future,
  ) async {
    final existingValue = get()!.data;

    try {
      update(data);
      await future;
    } catch (e) {
      update(existingValue);
    }
  }

  Future<void> optimisticCreate(
    T data,
    Future future,
  ) async {
    try {
      create(data);
      await future;
    } catch (e) {
      delete();
    }
  }
}
