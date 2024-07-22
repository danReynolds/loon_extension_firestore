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
      LoonExtensionFirestore.instance._onWrite(this, data);
      await future;
    } catch (e) {
      LoonExtensionFirestore.instance._onWrite(this, existingValue);
    }
  }

  Future<void> optimisticCreate(
    T data,
    Future future,
  ) async {
    try {
      LoonExtensionFirestore.instance._onWrite(this, data);
      await future;
    } catch (e) {
      delete();
    }
  }
}
