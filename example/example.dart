// ignore_for_file: avoid_print

import 'package:surrealdb/surrealdb.dart';

void main(List<String> args) async {
  const options = SurrealDBOptions();

  final client = SurrealDB('ws://localhost:8000/rpc', options: options)
    ..connect();
  await client.wait();
  await client.use('test', 'test');
  await client.signin(user: 'root', pass: 'root');

  final person = await client.create(
    'person',
    TestModel(marketing: false, title: 'Title'),
  );

  final person2 = await client.create('person', {
    'title': 'Founder & CEO',
    'name': {
      'first': 'Tobie',
      'last': 'Morgan Hitchcock',
    },
    'marketing': false,
  });

  final persons = await client.select<Map<String, dynamic>>('person');

  final groupByQuery = await client.query(
    r'SELECT marketing, count() FROM type::table($tb) GROUP BY marketing',
    {
      'tb': 'person',
    },
  );

  print(person);
  print(person2);
  print(persons);
  print(groupByQuery);
  client.close();
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
