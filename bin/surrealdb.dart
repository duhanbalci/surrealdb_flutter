// ignore_for_file: avoid_print

import 'package:surrealdb/surrealdb.dart';

void main(List<String> args) async {
  final client = SurrealDB('ws://localhost:8000/rpc')..connect();
  await client.wait();
  await client.use('ns', 'db');
  await client.signin(user: 'root', pass: 'root');

  final data = {
    'title': 'Founder & CEO',
    'name': {
      'first': 'Tobie',
      'last': 'Morgan Hitchcock',
    },
    'marketing': false,
  };

  final streamQuery = await client.liveQuery('live select * from person');

  await client.create('person', data);

  await for (final event in streamQuery.stream) {
    print(event);
  }
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
