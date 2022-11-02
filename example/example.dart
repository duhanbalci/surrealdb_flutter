import 'package:surrealdb/surrealdb.dart';

void main(List<String> args) async {
  final options = SurrealDBOptions(
    timeoutDuration: const Duration(seconds: 30),
  );

  var client = SurrealDB('ws://localhost:8000/rpc', options: options);

  client.connect();
  await client.wait();
  await client.use('test', 'test');
  await client.signin('root', 'root');

  var person = await client.create('person', TestModel(false, 'Title'));

  var person2 = await client.create('person', {
    'title': 'Founder & CEO',
    'name': {
      'first': 'Tobie',
      'last': 'Morgan Hitchcock',
    },
    'marketing': false,
  });

  var persons = await client.select('person');

  var groupByQuery = await client.query(
    'SELECT marketing, count() FROM type::table(\$tb) GROUP BY marketing',
    {
      'tb': 'person',
    },
  );

  print(person);
  print(person2);
  print(persons);
  print(groupByQuery);
}

class TestModel {
  final bool marketing;
  final String title;

  TestModel(this.marketing, this.title);

  static fromJson(Map<String, dynamic> json) {
    return TestModel(json['marketing'], json['title']);
  }

  toJson() {
    return {
      'marketing': marketing,
      'title': title,
    };
  }
}
