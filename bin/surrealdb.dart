// ignore_for_file: avoid_print

import 'package:surrealdb/surrealdb.dart';

void main(List<String> args) async {
  final client = SurrealDB('ws://localhost:8000/rpc')..connect();

  // wait for connection
  await client.wait();
  // use test namespace and test database
  await client.use('test', 'test');
  // authenticate with user and pass
  await client.signin(user: 'root', pass: 'root');

  final data = {
    'title': 'Founder & CEO',
    'name': {
      'first': 'Tobie',
      'last': 'Morgan Hitchcock',
    },
    'marketing': false,
  };

  // create record in person table with map
  final person = await client.create('person', data);

  print(person);

  // select all records from person table
  final persons = await client.select('person');

  print(persons.length);

  // group by marketing column
  final groupBy = await client.query(
    r'SELECT marketing, count() FROM type::table($tb) GROUP BY marketing',
    {
      'tb': 'person',
    },
  );

  print(groupBy);

  // live query stream
  final streamQuery = await client.liveQuery('live select * from person');

  //
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
