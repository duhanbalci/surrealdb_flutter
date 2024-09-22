// ignore_for_file: avoid_print

import 'package:surrealdb/surrealdb.dart';

void main(List<String> args) async {
  final db = SurrealDB('ws://localhost:8000/rpc')..connect();

  // wait for connection
  await db.wait();
  // Use a specific namespace and database
  await db.use('namespace', 'database');

  await db.signin(user: 'root', pass: 'root');
}

class AMODEL {
  AMODEL({
    required this.id,
    required this.marketing,
    required this.title,
  });

  factory AMODEL.fromJson(Map<String, dynamic> json) {
    return AMODEL(
      id: json['id'] as String,
      marketing: json['marketing'] as bool,
      title: json['title'] as String,
    );
  }

  final String id;
  final bool marketing;
  final String title;
}

class TestModel {
  TestModel({required this.marketing, required this.title});

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      marketing: json['marketing'] as bool,
      title: json['title'] as String,
    );
  }

  final bool marketing;
  final String title;

  Map<String, Object> toJson() {
    return {
      'marketing': marketing,
      'title': title,
    };
  }
}
