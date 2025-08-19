import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loon/loon.dart';
import 'package:loon_extension_firestore/loon_extension_firestore.dart';

import 'models/test_user_model.dart';

void main() {
  setUp(() async {
    LoonExtensionFirestore.configure(enabled: false);
    await Future.wait([
      FakeFirebaseFirestore().clearPersistence(),
      Loon.clearAll(),
    ]);
  });

  group(
    'Loon Extension Firestore',
    () {
      test(
        'Should not sync remote data to local cache when disabled',
        () async {
          final firestore = FakeFirebaseFirestore();
          final dataSource = CollectionDataSource(
            local: Loon.collection('users'),
            remote: firestore.collection('users'),
          );

          final userData = {
            "name": "John",
            "age": 24,
          };

          dataSource.remote.doc('1').create(userData);

          expect(
            dataSource.local.get(),
            [],
          );
        },
      );

      test(
        'Should sync remote data to local cache when enabled',
        () async {
          final firestore = FakeFirebaseFirestore();

          final dataSource = CollectionDataSource(
            local: Loon.collection('users'),
            remote: firestore.collection('users'),
          );

          final userData = {
            "name": "John",
            "age": 24,
          };

          LoonExtensionFirestore.configure(
            enabled: true,
            onBeforeWrite: (localDoc, remoteSnap, serializer) {
              expect(localDoc, dataSource.doc('1').local);
              expect(remoteSnap.data(), userData);
              return true;
            },
            onWrite: (snap) {
              expect(snap.data, userData);
            },
          );

          dataSource.remote.doc('1').create(userData);

          final remoteQuerySnap = await dataSource.remote.get();
          expect(remoteQuerySnap, [userData]);

          final remoteDocSnap = await dataSource.doc('1').remote.get();
          expect(remoteDocSnap, userData);
        },
      );

      test(
        'Should write data optimistically when specified',
        () async {
          final firestore = FakeFirebaseFirestore();

          final userData = {
            "name": "John",
            "age": 24,
          };

          LoonExtensionFirestore.configure(enabled: true);

          final dataSource = CollectionDataSource(
            local: Loon.collection('users'),
            remote: firestore.collection('users'),
          );

          final localSnap = LocalDocumentSnapshot(
            doc: dataSource.local.doc('1'),
            data: userData,
          );

          dataSource.remote.doc('1').create(userData, optimistic: false);
          expect(localSnap.doc.exists(), false);

          dataSource.remote.doc('1').create(userData, optimistic: true);
          expect(localSnap.doc.exists(), true);
        },
      );

      test(
        'Should not write if canceled by onBeforeWrite',
        () async {
          final firestore = FakeFirebaseFirestore();

          final userData = {
            "name": "John",
            "age": 24,
          };

          LoonExtensionFirestore.configure(
            enabled: true,
            onBeforeWrite: (localDoc, remoteSnap, serializer) {
              return remoteSnap.id == '1';
            },
          );

          final dataSource = CollectionDataSource(
            local: Loon.collection('users'),
            remote: firestore.collection('users'),
          );

          dataSource.remote.doc('1').create(userData);
          final remoteSnap = await dataSource.remote.doc('1').get();
          expect(remoteSnap, userData);

          dataSource.remote.doc('2').create(userData);
          final remoteSnap2 = await dataSource.remote.doc('2').get();
          expect(remoteSnap2, null);
        },
      );

      test(
        'Should parse data using the given serializer',
        () async {
          final firestore = FakeFirebaseFirestore();
          LoonExtensionFirestore.configure(enabled: true);

          final dataSource = CollectionDataSource<TestUserModel>(
            local: Loon.collection('users'),
            remote: firestore.collection('users'),
            serializer: Serializer(
              TestUserModel.fromJson,
              (user) => user.toJson(),
            ),
          );

          final user = TestUserModel(name: 'User 1');

          dataSource.remote.doc('1').create(user);
          final remoteSnap = await dataSource.remote.doc('1').get();
          expect(remoteSnap, user);
        },
      );
    },
  );
}
