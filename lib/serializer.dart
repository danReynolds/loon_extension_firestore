part of loon_extension_firestore;

class Serializer<T> {
  final FromJson<T> fromJson;
  final ToJson<T> toJson;

  Serializer(this.fromJson, this.toJson);
}
