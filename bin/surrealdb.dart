// ignore_for_file: avoid_print

import 'package:surrealdb/src/common/types.dart';
import 'package:surrealdb/surrealdb.dart';

void main(List<String> args) async {
  final db = SurrealDB('ws://localhost:8000/rpc')..connect();

  // wait for connection
  await db.wait();
  // Use a specific namespace and database
  await db.use('namespace', 'database');

//   await db.signin(user: 'root', pass: 'root');

//   await db.query(r'''
// DEFINE ACCESS users ON DATABASE TYPE RECORD
// 	SIGNUP ( CREATE user SET email = $email, pass = crypto::argon2::generate($pass) )
// 	SIGNIN ( SELECT * FROM user WHERE email = $email AND crypto::argon2::compare(pass, $pass) )
// 	DURATION FOR TOKEN 15m, FOR SESSION 12h;
// ''');

  final token = await db.signin(
    user: 'root',
    pass: 'root',
    // namespace: 'namespace',
    // database: 'database',
    // access: 'users',
  );
  // print('User signed up with token: $token');

  // await db.authenticate(token);

  // Fetch version information
  // final version = await db.query(r'SELECT * FROM $session');
  // print('SurrealDB version: $version');

  final liveQuery =
      await db.liveQuery('LIVE SELECT * FROM posts WHERE active = true');
  liveQuery.stream.listen((event) {
    print('Action: "${event.action}", result: ${event.result}');
  });

  await db.create('posts', {
    'title': 'My first post',
    'content': 'Hello, SurrealDB!',
  });
  await db.create('posts', {
    'title': 'My second post',
    'content': 'Hello, SurrealDB!',
    'active': true
  });
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
