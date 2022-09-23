import 'package:surrealdb/src/surrealdb.dart';
import 'package:surrealdb/surrealdb.dart';

void main(List<String> args) async {
  var client = SurrealDB('ws://localhost:8000/rpc');
  client.connect();
  await client.wait();
  await client.use('test', 'test');
  await client.signin('root', 'root');
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
  // await client.live(
  //   'person',
  //   {
  //     'tb': 'person',
  //   },
  // );
  // await client.query('live select * from person');
  // Timer.periodic(const Duration(seconds: 5), (timer) async {
  //   var s = await client.create('person', {
  //     'title': 'Founder & CEO',
  //     'name': {
  //       'first': 'Tobie',
  //       'last': 'Morgan Hitchcock',
  //     },
  //     'marketing': false,
  //   });
  //   // print(s);
  // });
  await client.create('person', TestModel(false, 'Title'));
  // var s = await client.query("SELECT count() from person group by id");
  // ws.connect('asd');
}

class AMODEL {
  final String id;
  final bool marketing;
  final String title;

  AMODEL(this.id, this.marketing, this.title);

  static fromJson(Map<String, dynamic> json) {
    return AMODEL(json['id'], json['marketing'], json['title']);
  }
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
