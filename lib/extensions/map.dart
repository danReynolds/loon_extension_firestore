part of loon_extension_firestore;

extension MapExtensions<T, S> on Map<T, S> {
  Map<T, S> pick(Set<T>? keys) {
    if (keys == null || keys.isEmpty) {
      return this;
    }

    return keys.fold(
      {},
      (acc, key) => {
        ...acc,
        key: this[key] as S,
      },
    );
  }
}
