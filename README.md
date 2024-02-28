[![Tests](https://github.com/duhanbalci/surrealdb_flutter/actions/workflows/dart-test.yml/badge.svg?branch=main)](https://github.com/duhanbalci/surrealdb_flutter/actions/workflows/dart-test.yml)

# SurrealDB Client For Dart & Flutter

SurrealDB client for Dart and Flutter.

## Quick Start

```dart
import 'package:surrealdb/surrealdb.dart';

void main(List<String> args) async {
  final client = SurrealDB('ws://localhost:8000/rpc')..connect();

  // wait for connection
  await client.wait();
  // use test namespace and test database
  await client.use('test', 'test');
  // authenticate with user and pass
  await client.signin(user: 'root', pass: 'root');

  // create record in person table with json encodable object
  await client.create('person', TestModel(false, 'title'));

  final data = {
    'title': 'Founder & CEO',
    'name': {
      'first': 'Tobie',
      'last': 'Morgan Hitchcock',
    },
    'marketing': false,
  };

  // create record in person table with map
  var person = await client.create('person', data);

  print(person);

  // select all records from person table
  List<Map<String, Object?>> persons = await client.select('person');

  print(persons.length);

  // group by marketing column
  final groupBy = await client.query(
    'SELECT marketing, count() FROM type::table(\$tb) GROUP BY marketing',
    {
      'tb': 'person',
    },
  );

  print(groupBy);

  // patch the record
  final change = await client.change(
     'person:tobie', [
	 { op: 'replace', path: '/name/last', value: 'Hitchcock' },
	 { op: 'add', path: '/tags', value: ['developer', 'engineer'] },
	 { op: 'remove', path: '/marketing' },
   ],
  );

  print(change);

  // live query stream
  final streamQuery = await client.liveQuery('live select * from person');

  //
  await client.create('person', data);

  await for (final event in streamQuery.stream) {
    print(event);
  }
}
```

## Features

### `connect()`

Connects to a database endpoint provided in constructer and authenticate with token if provided in constructer.

### `close()`

Closes the persistent connection to the database.

### `wait()`

Ensures connections established with the database and pinged successfully.

### `ping()`

Closes the persistent connection to the database.

### `use(String namespace, String database)`

Switch to a specific namespace and database.

### `info()`

Retrieve info about the current Surreal instance

### `signup(String user, String pass)`

Signs up to a specific authentication scope

### `signin(String user, String pass)`

Signs in to a specific authentication scope

### `invalidate()`

Invalidates the authentication for the current connection

### `authenticate(String token)`

Authenticates the current connection with a JWT token

### `kill(String query)`

Kill a specific query

### `let(String key, String val)`

Assigns a value as a parameter for this connection

### `create(String thing, dynamic data)`

Creates a record in the database. `data` has to be json encodable object or `class` has `toJson` method.

### `Future<List<T>> select(String table)`

Selects all records in a table, or a specific record, from the database

### `query(String query, [Map<String, Object?>? vars])`

Runs a set of SurrealQL statements against the database

### `update(String thing, [Object? data])`

Updates all records in a table, or a specific record, in the database
**_NOTE: This function replaces the current document / record data with the specified data._**

### `change(String thing, [Object? data])`
Applies JSON Patch changes to all records, or a specific record, in the database
**_NOTE: This function patches the current document / record data with the specified [JSON Patch](https://jsonpatch.com/) data._**

### `delete(String thing)`

Deletes all records in a table, or a specific record, from the database

### `liveQuery(String query, [Map<String, Object?>? vars])`

Creates a live query stream
