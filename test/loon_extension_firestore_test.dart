import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loon/loon.dart';
import 'package:loon_extension_firestore/loon_extension_firestore.dart';

void main() {
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
        () {
          final firestore = FakeFirebaseFirestore();
          LoonExtensionFirestore.configure(enabled: true);

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
            [
              DocumentSnapshot(doc: dataSource.local.doc('1'), data: userData),
            ],
          );
        },
      );
    },
  );
}
