# Loon Extension Firestore

The [Loon](https://github.com/danReynolds/loon) Firestore extension used to easily sync documents fetched remotely from Firestore into the local Loon cache.

## Install
```dart
flutter pub add loon_extension_firestore
```

## Getting started

Start by enabling the Loon Firestore extension, which will disable the default Firestore cache and enable syncing of Firestore documents to Loon instead.

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  LoonExtensionFirestore.configure(enabled: true);
  
  return runApp(MyApp());
}
```

## Data Source

Next, initialize a data source that defines how to access your data both remotely in Firestore and locally in your Loon cache.

```dart
import 'package:loon_extension_firestore/loon_extension_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final dataSource = CollectionDataSource(
  local: Loon.collection('users'),
  remote: FirebaseFirestore.instance.collection('users'),
);
```

Any data fetched through the data source will now automatically be written to the cache.

```dart
// Fetch the users collection remotely from Firestore
final remoteUsersSnap = await dataSource.remote.get();
// Access the automatically cached users collection in Loon.
final localUsers = dataSource.local.get();
```

## Typed Data

If your collection can be parsed into a type-safe data model, then you can specify a serializer on your data source:

```dart
class UserModel {
  final String id;
  final String name;

  UserModel({
    required this.id,
    required this.name,
  });

  Json toJson() {
    return {
      "id": id,
      "name": name,
    }
  }
}

final dataSource = CollectionDataSource(
  serializer: Serializer(
    UserModel.fromJson,
    (user) => user.toJson(),
  ),
  local: Loon.collection('users'),
  remote: FirebaseFirestore.instance.collection('users'),
);
```

This combines the need to specify a converter for the Firestore collection and for the Loon collection reference.

## Lifecycle handlers

* **onWrite**: The `onWrite` handler can be used to perform a side-effect when a remote Firestore document is written to the local Loon cache.

```dart
LoonExtensionFirestore.configure(
  enabled: true,
  onWrite: (snap) {
    print(snap.path); // users__1
  },
);

final dataSource = CollectionDataSource(
  serializer: Serializer(
    UserModel.fromJson,
    (user) => user.toJson(),
  ),
  local: Loon.collection('users'),
  remote: FirebaseFirestore.instance.collection('users'),
);

final snap = await dataSource.doc('1').remote.get();
```

* **onBeforeWrite**: The `onBeforeWrite` handler fires before a Firestore document is written to the local Loon cache and allows writing of documents to the cache to be canceled if the event returns false.

```dart
LoonExtensionFirestore.configure(
  enabled: true,
  onBeforeWrite: (localDoc, remoteSnap, serializer) {
    if (condition) {
      return false; // Conditionally do not write to the Loon cache.
    }
    return true; 
  }
);
```

