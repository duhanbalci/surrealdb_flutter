import 'package:surrealdb/src/surrealdb.dart';
import 'package:surrealdb/surrealdb.dart';

void main(List<String> args) async {
  var client = SurrealDB('ws://localhost:8000/rpc');

  await client.connect();

  await client.use('test', 'test');

  await client.signin('root', 'root');

  await client.create('person', PersonModel(false, 'Title'));

  await client.create('person', {
    'title': 'Founder & CEO',
    'name': {
      'first': 'Tobie',
      'last': 'Morgan Hitchcock',
    },
    'marketing': false,
  });

  await client.select('person');

  await client.query(
    'SELECT marketing, count() FROM type::table(\$tb) GROUP BY marketing',
    {
      'tb': 'person',
    },
  );

  await client.live('person');

  await client.query('live select * from person');
}

class PersonModel {
  final bool marketing;
  final String title;

  PersonModel(this.marketing, this.title);

  static fromJson(Map<String, dynamic> json) {
    return PersonModel(json['marketing'], json['title']);
  }
}
