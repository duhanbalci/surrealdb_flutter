import 'dart:async';

import 'package:surrealdb/surrealdb.dart';
import 'package:test/test.dart';

void main() {
  const testUrl = 'ws://127.0.0.1:8000/rpc';

  test('should connect & disconnect', () async {
    final client = SurrealDB(testUrl)..connect();
    await client.wait();
    client.close();
    await Future<dynamic>.delayed(const Duration(seconds: 1));
  });

  test('should connect, use, signin, close', () async {
    final client = SurrealDB(testUrl)..connect();
    await client.wait();
    await client.use('ns', 'db');
    await client.signin(user: 'root', pass: 'root');
    client.close();
    await Future<dynamic>.delayed(const Duration(seconds: 1));
  });

  test('should create', () async {
    final client = SurrealDB(testUrl)..connect();
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
    final res = await client.create('person', data);
    final person = (res! as List)[0] as Map<String, dynamic>;

    expect(person['id'], isNotNull);
    expect(person['title'], data['title']);
    expect(
      (person['name']! as Map<String, dynamic>)['first'],
      (data['name']! as Map<String, dynamic>)['first'],
    );
    expect(
      (person['name']! as Map<String, dynamic>)['last'],
      (data['name']! as Map<String, dynamic>)['last'],
    );
    expect(person['marketing'], data['marketing']);
  });

  test('should delete,select', () async {
    final client = SurrealDB(testUrl)..connect();
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
    await client.delete('person');
    final res = await client.create('person', data);
    var person = (res! as List)[0] as Map<String, dynamic>;

    expect(person['id'], isNotNull);
    expect(person['title'], data['title']);
    expect(
      (person['name']! as Map<String, dynamic>)['first'],
      (data['name']! as Map<String, dynamic>)['first'],
    );
    expect(
      (person['name']! as Map<String, dynamic>)['last'],
      (data['name']! as Map<String, dynamic>)['last'],
    );
    expect(person['marketing'], data['marketing']);

    final persons = await client.select<Map<String, dynamic>>('person');
    expect(persons.length, 1);
    person = persons[0];
    expect(person['id'], isNotNull);
    expect(person['title'], data['title']);
    expect(
      (person['name']! as Map<String, dynamic>)['first'],
      (data['name']! as Map<String, dynamic>)['first'],
    );
    expect(
      (person['name']! as Map<String, dynamic>)['last'],
      (data['name']! as Map<String, dynamic>)['last'],
    );
    expect(person['marketing'], data['marketing']);
  });

  test('should select one', () async {
    final client = SurrealDB(testUrl)..connect();
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
    await client.delete('person');
    final res = await client.create('person', data);
    var person = (res! as List)[0] as Map<String, dynamic>;

    expect(person['id'], isNotNull);
    expect(person['title'], data['title']);
    expect(
      (person['name']! as Map<String, dynamic>)['first'],
      (data['name']! as Map<String, dynamic>)['first'],
    );
    expect(
      (person['name']! as Map<String, dynamic>)['last'],
      (data['name']! as Map<String, dynamic>)['last'],
    );
    expect(person['marketing'], data['marketing']);

    final persons = await client.select<Map<String, dynamic>>('person');
    expect(persons.length, 1);
    person = persons[0];
    expect(person['id'], isNotNull);
    expect(person['title'], data['title']);
    expect(
      (person['name']! as Map<String, dynamic>)['first'],
      (data['name']! as Map<String, dynamic>)['first'],
    );
    expect(
      (person['name']! as Map<String, dynamic>)['last'],
      (data['name']! as Map<String, dynamic>)['last'],
    );
    expect(person['marketing'], data['marketing']);

    try {
      await client.select<Map<String, dynamic>>(person['id'] as String);
    } catch (e) {
      fail('exception thrown when selecting one: $e');
    }
  });

  /// Might no work with SurrealDB Release v1.0.0-beta.9
  test('live queries', () async {
    final client = SurrealDB(testUrl)..connect();
    await client.wait();
    await client.use('ns', 'db');
    await client.signin(user: 'root', pass: 'root');

    await client.delete('person');

    final res = Completer<LiveQueryResponse>();

    final data = {
      'title': 'Founder & CEO',
      'name': {
        'first': 'Tobie',
        'last': 'Morgan Hitchcock',
      },
      'marketing': false,
    };

    final queryUuid = parseUuid(
      // ignore: avoid_dynamic_calls, cast_nullable_to_non_nullable
      (await client.query('Live Select * From person') as List)[0]['result'],
    );

    client.listenLive(queryUuid, res.complete);

    await client.create('person', data);

    Future.delayed(const Duration(seconds: 1), () {
      res.completeError(Exception('Live query response error'));
    });

    expect(await res.future, isA<LiveQueryResponse>());
  });
}
