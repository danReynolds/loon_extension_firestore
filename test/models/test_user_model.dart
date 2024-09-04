import 'package:loon/loon.dart';

class TestUserModel {
  final String name;

  TestUserModel({
    required this.name,
  });

  factory TestUserModel.fromJson(Json json) {
    return TestUserModel(name: json['name']);
  }

  @override
  bool operator ==(Object other) {
    return other is TestUserModel && other.name == name;
  }

  @override
  int get hashCode => Object.hashAll([name]);

  toJson() {
    return {
      "name": name,
    };
  }
}
