import 'package:surrealdb/src/surrealdb.dart';
import 'package:surrealdb/surrealdb.dart';

void main(List<String> args) async {
  final client = SurrealDB('ws://localhost:8000/rpc');

  client.connect();
  await client.wait();
  await client.use('ns', 'db');
  await client.signin('root', 'root');

  final delete = await client.query('DELETE user:5');

  print(delete);
  client.close();
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
