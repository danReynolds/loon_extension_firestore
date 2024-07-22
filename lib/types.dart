part of loon_extension_firestore;

typedef LoonCollection<T> = loon.Collection<T>;
typedef LocalCollection<T> = loon.Collection<T>;
typedef FirestoreCollection<T> = firestore.CollectionReference<T>;
typedef FirestoreQuery<T> = firestore.Query<T>;

typedef LoonDocument<T> = loon.Document<T>;
typedef LocalDocument<T> = loon.Document<T>;
typedef FirestoreDocument<T> = firestore.DocumentReference<T>;

typedef FromJson<T> = loon.FromJson<T>;
typedef ToJson<T> = loon.ToJson<T>;

typedef LocalDocumentSnapshot<T> = loon.DocumentSnapshot<T>;
typedef RemoteDocumentSnapshot<T> = firestore.DocumentSnapshot<T>;
