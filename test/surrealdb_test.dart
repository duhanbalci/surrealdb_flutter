import 'dart:async';

import 'package:surrealdb/surrealdb.dart';
import 'package:test/test.dart';

void main() {
  const testUrl = 'ws://localhost:8000/rpc';

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
}
