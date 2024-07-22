# Loon Extension Firestore

The [Loon](https://github.com/danReynolds/loon) Firestore extension used to easily sync documents fetched remotely from Firestore into the local Loon cache.

## Install
```dart
pub add loon_extension_firestore
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
