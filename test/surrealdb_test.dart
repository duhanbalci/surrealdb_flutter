import 'dart:async';

import 'package:test/test.dart';

import 'package:surrealdb/surrealdb.dart';

void main() {
  const _testUrl = 'ws://localhost:8000/rpc';

  test('should connect & disconnect', () async {
    final client = SurrealDB(_testUrl);
    client.connect();
    await client.wait();
    client.close();
    await Future.delayed(Duration(seconds: 1));
  });

  test('should connect, use, signin, close', () async {
    final client = SurrealDB(_testUrl);
    client.connect();
    await client.wait();
    await client.use('ns', 'db');
    await client.signin('root', 'root');
    client.close();
    await Future.delayed(Duration(seconds: 1));
  });

  test('should create', () async {
    final client = SurrealDB(_testUrl);
    client.connect();
    await client.wait();
    await client.use('ns', 'db');
    await client.signin('root', 'root');
    var data = {
      'title': 'Founder & CEO',
      'name': {
        'first': 'Tobie',
        'last': 'Morgan Hitchcock',
      },
      'marketing': false,
    };
    var res = await client.create('person', data);
    var person = (res as List)[0] as Map<String, dynamic>;

    expect(person['id'], isNotNull);
    expect(person['title'], data['title']);
    expect(person['name']['first'],
        (data['name'] as Map<String, dynamic>)['first']);
    expect(
        person['name']['last'], (data['name'] as Map<String, dynamic>)['last']);
    expect(person['marketing'], data['marketing']);
  });

  test('should delete,select', () async {
    final client = SurrealDB(_testUrl);
    client.connect();
    await client.wait();
    await client.use('ns', 'db');
    await client.signin('root', 'root');
    var data = {
      'title': 'Founder & CEO',
      'name': {
        'first': 'Tobie',
        'last': 'Morgan Hitchcock',
      },
      'marketing': false,
    };
    await client.delete('person');
    var res = await client.create('person', data);
    var person = (res as List)[0] as Map<String, dynamic>;

    expect(person['id'], isNotNull);
    expect(person['title'], data['title']);
    expect(person['name']['first'],
        (data['name'] as Map<String, dynamic>)['first']);
    expect(
        person['name']['last'], (data['name'] as Map<String, dynamic>)['last']);
    expect(person['marketing'], data['marketing']);

    var persons = await client.select('person');
    expect(persons.length, 1);
    person = persons[0] as Map<String, dynamic>;
    expect(person['id'], isNotNull);
    expect(person['title'], data['title']);
    expect(person['name']['first'],
        (data['name'] as Map<String, dynamic>)['first']);
    expect(
        person['name']['last'], (data['name'] as Map<String, dynamic>)['last']);
    expect(person['marketing'], data['marketing']);
  });

  test('should select one', () async {
    final client = SurrealDB(_testUrl);
    client.connect();
    await client.wait();
    await client.use('ns', 'db');
    await client.signin('root', 'root');
    var data = {
      'title': 'Founder & CEO',
      'name': {
        'first': 'Tobie',
        'last': 'Morgan Hitchcock',
      },
      'marketing': false,
    };
    await client.delete('person');
    var res = await client.create('person', data);
    var person = (res as List)[0] as Map<String, dynamic>;

    expect(person['id'], isNotNull);
    expect(person['title'], data['title']);
    expect(person['name']['first'],
        (data['name'] as Map<String, dynamic>)['first']);
    expect(
        person['name']['last'], (data['name'] as Map<String, dynamic>)['last']);
    expect(person['marketing'], data['marketing']);

    var persons = await client.select('person');
    expect(persons.length, 1);
    person = persons[0] as Map<String, dynamic>;
    expect(person['id'], isNotNull);
    expect(person['title'], data['title']);
    expect(person['name']['first'],
        (data['name'] as Map<String, dynamic>)['first']);
    expect(
        person['name']['last'], (data['name'] as Map<String, dynamic>)['last']);
    expect(person['marketing'], data['marketing']);

    try {
      await client.select(person['id']);
    } catch (e) {
      fail('exception thrown when selecting one: $e');
    }
  });
}
