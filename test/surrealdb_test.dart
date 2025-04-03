import 'dart:async';

import 'package:surrealdb/src/common/types.dart';
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
    final person = res as Map<String, dynamic>?;

    expect(person, isNotNull);
    expect(person!['id'], isNotNull);
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

  test('should delete, select', () async {
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
    var person = res as Map<String, dynamic>?;

    expect(person, isNotNull);
    expect(person!['id'], isNotNull);
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

  test('should patch', () async {
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
    final person = res as Map<String, dynamic>?;

    expect(person, isNotNull);
    expect(person!['id'], isNotNull);

    final patched = await client.patch(person['id'] as String, [
      const AddPatch('/name/middle', 'Morgan'),
      const ReplacePatch('/title', 'Janitor'),
      const RemovePatch('/name/last'),
      const CopyPatch('/name/firstCopy', '/name/first'),
      const CopyPatch('/name/firstCopy2', '/name/firstCopy'),
      const MovePatch('/name/firstCopy2Moved', '/name/firstCopy2'),
      const TestPatch('/name/firstCopy2Moved', 'Tobie'),
    ]);

    expect(patched, isNotNull);

    final persons = await client.select<Map<String, dynamic>>('person');
    final patchedPerson = persons.first;

    expect(patchedPerson['id'], isNotNull);

    final patchedPersonName = patchedPerson['name']! as Map<String, dynamic>;

    expect(patchedPersonName['middle'], 'Morgan');
    expect(patchedPerson['title'], 'Janitor');
    expect(patchedPersonName['last'], isNull);
    expect(patchedPersonName['firstCopy'], 'Tobie');
    expect(patchedPersonName['firstCopy2'], isNull);
    expect(patchedPersonName['firstCopy2Moved'], 'Tobie');
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
    var person = res as Map<String, dynamic>?;

    expect(person, isNotNull);
    expect(person!['id'], isNotNull);
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

    final data = {
      'title': 'Founder & CEO',
      'name': {
        'first': 'Tobie',
        'last': 'Morgan Hitchcock',
      },
      'marketing': false,
    };

    // test live query
    final streamQuery = await client.liveQuery('live select * from person');

    await client.create('person', data);

    expect(streamQuery.stream, emits(isA<LiveQueryResponse>()));

    await client.delete('person');

    // test live table
    final streamTable = await client.liveTable('person');

    await client.create('person', data);

    expect(streamTable.stream, emits(isA<LiveQueryResponse>()));

    await client.delete('person');

    // test kill query

    final streamQuery2 = await client.liveQuery('live select * from person');

    await client.create('person', data);

    await streamQuery2.kill();

    expect(streamQuery2.isClosed, true);
  });

  group('Middleware tests', () {
    late SurrealDB client;

    setUp(() async {
      client = SurrealDB(testUrl)..connect();
      await client.wait();
      await client.use('ns', 'db');
      await client.signin(user: 'root', pass: 'root');
    });

    tearDown(() {
      client.close();
    });

    test('single middleware should be called before and after request',
        () async {
      // Setup test tracking variables
      var beforeCalled = false;
      var afterCalled = false;
      var capturedMethod = '';
      var capturedParams = <Object?>[];
      Object? capturedResult;

      // Add middleware
      client.addMiddleware((method, params, next) async {
        // Before request
        beforeCalled = true;
        capturedMethod = method;
        capturedParams = params;

        // Execute the request
        final result = await next();

        // After request
        afterCalled = true;
        capturedResult = result;

        return result;
      });

      // Make a request
      await client.version();

      // Verify middleware was called correctly
      expect(beforeCalled, isTrue);
      expect(afterCalled, isTrue);
      expect(capturedMethod, equals(Methods.version));
      expect(capturedParams, equals([]));
      expect(capturedResult, isNotNull);
    });

    test('multiple middlewares should be called in correct order', () async {
      // Setup test tracking variables
      final callOrder = <String>[];

      // Add first middleware
      client.addMiddleware((method, params, next) async {
        callOrder.add('before1');
        final result = await next();
        callOrder.add('after1');
        return result;
      });

      // Add second middleware
      client.addMiddleware((method, params, next) async {
        callOrder.add('before2');
        final result = await next();
        callOrder.add('after2');
        return result;
      });

      // Make a request
      await client.version();

      // Verify middlewares were called in correct order
      expect(callOrder, equals(['before1', 'before2', 'after2', 'after1']));
    });

    test('middleware should be able to modify the result', () async {
      // Add middleware that modifies the result
      client.addMiddleware((method, params, next) async {
        final result = await next();

        // Only modify version results for this test
        if (method == Methods.version) {
          return 'modified-result';
        }

        return result;
      });

      // Make a request
      final result = await client.version();

      // Verify result was modified
      expect(result, equals('modified-result'));
    });

    test('middleware should handle errors properly', () async {
      // Add middleware that catches and transforms errors
      client.addMiddleware((method, params, next) async {
        try {
          return await next();
        } catch (e) {
          // Transform the error into a custom response
          return 'error-handled';
        }
      });

      // Add middleware that throws an error
      client.addMiddleware((method, params, next) async {
        if (method == Methods.version) {
          throw Exception('Test error');
        }
        return next();
      });

      // Make a request
      final result = await client.version();

      // Verify error was handled
      expect(result, equals('error-handled'));
    });

    test('middleware should demonstrate token refresh scenario', () async {
      // Setup test tracking variables
      var refreshCalled = false;
      var retryCalled = false;

      // Add token refresh middleware
      client.addMiddleware((method, params, next) async {
        try {
          // First attempt
          return await next();
        } catch (e) {
          // Simulate token refresh on auth error
          if (e.toString().contains('test-auth-error')) {
            refreshCalled = true;

            // Simulate getting a new token and re-authenticating
            // In a real scenario, this would call a token refresh API

            // Try again with "new" token
            retryCalled = true;
            return 'success-after-refresh';
          }
          rethrow;
        }
      });

      // Add middleware that simulates an auth error on first call
      client.addMiddleware((method, params, next) async {
        if (method == Methods.version && !retryCalled) {
          throw Exception('test-auth-error');
        }
        return next();
      });

      // Make a request
      final result = await client.version();

      // Verify token refresh flow
      expect(refreshCalled, isTrue);
      expect(retryCalled, isTrue);
      expect(result, equals('success-after-refresh'));
    });
  });
}
