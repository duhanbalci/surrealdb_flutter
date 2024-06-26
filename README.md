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

  // delete all records from person table
  await client.delete('person');

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

  // group by marketing column
  final groupBy = await client.query(
    'SELECT marketing, count() FROM type::table(\$tb) GROUP BY marketing',
    {
      'tb': 'person',
    },
  );

  print(groupBy);

  // select all records from person table
  List<Map<String, Object?>> persons = await client.select('person');

  print(persons.first);

   // JSON patch operations
  final patched = await client.patch(persons.first['id'] as String, [
    const AddPatch('/name/middle', 'Morgan'),
    const ReplacePatch('/title', 'Janitor'),
    const RemovePatch('/name/last'),
    const CopyPatch('/name/firstCopy', '/name/first'),
    const CopyPatch('/name/firstCopy2', '/name/firstCopy'),
    const MovePatch('/name/firstCopy2Moved', '/name/firstCopy2'),
    const TestPatch('/name/firstCopy2Moved', 'Tobie'),
  ]);

  print(patched);

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

### `merge(String thing, [Object? data])`

Modifies all records in a table, or a specific record, in the database
**_NOTE: This function merges the current document / record data with the specified data._**

### `patch(String thing, [List<Patch>? data])`

Applies JSON Patch changes to all records, or a specific record, in the database
**_NOTE: This function patches the current document / record data with the specified JSON Patch data._**

### `delete(String thing)`

Deletes all records in a table, or a specific record, from the database

### `liveQuery(String query, [Map<String, Object?>? vars])`

Creates a live query stream

