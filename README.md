# SurrealDB Client For Dart & Flutter

![Pub Version](https://img.shields.io/pub/v/surrealdb?logo=dart)
[![Tests](https://github.com/duhanbalci/surrealdb_flutter/actions/workflows/dart-test.yml/badge.svg?branch=main)](https://github.com/duhanbalci/surrealdb_flutter/actions/workflows/dart-test.yml)
![GitHub Issues or Pull Requests](https://img.shields.io/github/issues/duhanbalci/surrealdb_flutter?logo=github)

This is a Dart client library for interacting with [SurrealDB](https://surrealdb.com/docs/), a highly scalable, distributed, and real-time database. This library enables developers to connect to SurrealDB instances, execute queries, authenticate users, and interact with database resources via WebSocket communication.

## Features

- ⚡ Connect and Disconnect: Establish or close a persistent WebSocket connection to a SurrealDB instance.
- 🔐 Authentication: Authenticate with a token to manage access to the database.
- 🗄️ Database Interaction: Use namespaces and databases, retrieve user information, and fetch database versions.
- 🔄 Live Queries: Support for live querying via WebSocket streams.
- ⚙️ Customizable Options: Set connection options and behavior using SurrealDBOptions.

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  surrealdb: ^1.0.0
```
Then run `dart pub get` or `flutter pub get`.

## Usage

### Connecting to SurrealDB

To connect to a SurrealDB, create a SurrealDB client instance and call the `connect()` method. You can also provide a token for authentication.

```dart
import 'package:surrealdb/surrealdb.dart';

void main() async {
  // Create a SurrealDB client instance
  final db = SurrealDB('ws://localhost:8000', token: 'your-auth-token');

  // Connect to the database
  db.connect();

  // Wait for the connection to be established
  await db.wait();

  // Use a specific namespace and database
  await db.use('namespace', 'database');

  // Fetch version information
  final version = await db.version();
  print('SurrealDB version: $version');

  // Close the connection when done
  db.close();
}
```

### Authentication

SurrealDB requires authentication to access resources. You can sign up, sign in, and authenticate users using the SurrealDB client.

#### Signing Up a User

To create a new user:

```dart
final token = await db.signup(
  user: 'new_user',
  pass: 'password123',
  namespace: 'namespace',
  database: 'database',
  access: 'users',
);
print('User signed up with token: $token');
```

#### Signing In

To sign in an existing user:

```dart
final token = await db.signin(
  user: 'existing_user', 
  pass: 'password123',
  namespace: 'namespace',
  database: 'database',
  access: 'users',
);
print('User signed in with token: $token');
```

#### Token Authentication

You can also authenticate with a token:

```dart
await db.authenticate('your-auth-token');
```

### Basic Queries


SurrealDB allows executing a variety of commands, including CRUD operations (Create, Read, Update, Delete) via queries. Here's how you can perform simple database operations.

#### 3.1 Create Records

```dart
final data = {'title': 'My first post', 'content': 'Hello, SurrealDB!'};
final result = await db.create('posts', data);
print('Created record: $result');
```

#### 3.2 Read Records

To retrieve records, you can use the `select` method.

```dart
final posts = await db.select('posts');
print('Fetched posts: $posts');
```

You can also use queries to filter or manipulate the data:

```dart
final specificPosts = await db.query(
  r'SELECT * FROM posts WHERE title = $title',
  {'title': 'My first post'},
);
print('Posts matching criteria: $specificPosts');
```

#### 3.3 Update Records

Updating records is done by specifying the table and ID of the record:

```dart
final updatedData = {'title': 'Updated post title'};
await db.update('posts:id', updatedData);
print('Record updated successfully');
```

#### 3.4 Delete Records

To delete a record:

```dart
await db.delete('posts:id');
print('Record deleted');
```

### Live Queries

SurrealDB supports live queries over WebSocket. Use the LiveQuery class for subscribing to changes in data.

```dart
final liveQuery = await db.liveQuery('LIVE SELECT * FROM posts WHERE active = true');
liveQuery.stream.listen((event) {
  print('Received update: ${event.result}');
});

await db.create('posts', {
  'title': 'My first post',
});
await db.create('posts', {
  'title': 'My second post',
  'active': true
});
```

You can read more about all the available methods and classes in the [API documentation](https://pub.dev/documentation/surrealdb/latest).

## Contributions

Contributions are welcome! Feel free to submit issues, feature requests, or pull requests to improve this library.

## License

This project is licensed under the MIT License. See the [`LICENSE`](https://github.com/duhanbalci/surrealdb_flutter/blob/main/LICENSE) file for more details.