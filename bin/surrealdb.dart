// ignore_for_file: avoid_print

import 'package:surrealdb/surrealdb.dart';

void main(List<String> args) async {
  const options = SurrealDBOptions(
    timeoutDuration: Duration(seconds: 30),
  );

  final client = SurrealDB('ws://localhost:8000/rpc', options: options)
    ..connect();
  await client.wait();
  await client.use('test', 'test');
  // await client.signup(user: 'root', pass: 'root');
  await client.signin(user: 'root', pass: 'root');

  await client.create('person', TestModel(marketing: false, title: 'title'));

  final person = await client.create('person', {
    'title': 'Founder & CEO',
    'name': {
      'first': 'Tobie',
      'last': 'Morgan Hitchcock',
    },
    'marketing': false,
  });
  print(person);

  final persons = await client.select<Map<String, dynamic>>('person');

  final groupBy = await client.query(
    r'SELECT marketing, count() FROM type::table($tb) GROUP BY marketing',
    {
      'tb': 'person',
    },
  );

  print(groupBy);

  print(persons.length);
  client.close();
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
