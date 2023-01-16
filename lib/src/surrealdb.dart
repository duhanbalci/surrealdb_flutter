import 'package:surrealdb/src/pinger.dart';
import 'package:surrealdb/src/surrealdb_options.dart';

import './ws.dart';

class SurrealDB {
  final String url;
  final String? token;

  Pinger? _pinger;
  late final WSService _wsService;
  final SurrealDBOptions options;

  SurrealDB(
    this.url, {
    this.token,
    this.options = const SurrealDBOptions(),
  }) {
    _wsService = WSService(url, options);
  }

  /// Connects to a local or remote database endpoint.
  void connect() {
    _wsService.connect();
    _pinger = Pinger(const Duration(seconds: 30));
    _wsService.waitConnect.then((value) => _pinger?.start(() => ping()));
    if (token != null) authenticate(token!);
  }

  /// Closes the persistent connection to the database.
  void close() {
    _pinger?.stop();
    _pinger = null;
    _wsService.disconnect();
  }

  /// Waits for the connection to the database to succeed.
  Future<void> wait() async {
    return _wsService.waitConnect;
  }

  /// Ping SurrealDB instance
  Future<void> ping() async {
    await _wsService.rpc('ping');
  }

  /// Switch to a specific namespace and database.
  /// @param ns - Switches to a specific namespace.
  /// @param db - Switches to a specific database.
  Future<void> use(String ns, String db) {
    return _wsService.rpc('use', [ns, db]);
  }

  /// Retreive info about the current Surreal instance
  /// @return Returns nothing!
  Future<Object?> info() {
    return _wsService.rpc('info');
  }

  /// Signs up to a specific authentication scope.
  ///
  /// [extra] - can be used for scope authentication
  /// @return The authenication token.
  Future<String> signup({
    String? user,
    String? pass,
    String? namespace,
    String? database,
    String? scope,
    Map<String, Object?>? extra,
  }) async {
    var object = <String, Object?>{};
    if (user != null) object['user'] = user;
    if (pass != null) object['pass'] = pass;
    if (namespace != null) object['NS'] = namespace;
    if (database != null) object['DB'] = database;
    if (scope != null) object['SC'] = scope;
    if (extra != null) object.addAll(extra);

    return (await _wsService.rpc('signup', [object])) as String;
  }

  /// Signs in to a specific authentication scope.
  ///
  /// [extra] - can be used for scope authentication
  /// @return The authenication token.
  Future<Object?> signin({
    String? user,
    String? pass,
    String? namespace,
    String? database,
    String? scope,
    Map<String, Object?>? extra,
  }) {
    var object = <String, Object?>{};
    if (user != null) object['user'] = user;
    if (pass != null) object['pass'] = pass;
    if (namespace != null) object['NS'] = namespace;
    if (database != null) object['DB'] = database;
    if (scope != null) object['SC'] = scope;
    if (extra != null) object.addAll(extra);

    return _wsService.rpc('signin', [object]);
  }

  /// Invalidates the authentication for the current connection.
  Future<void> invalidate() {
    return _wsService.rpc('invalidate');
  }

  /// Authenticates the current connection with a JWT token.
  /// @param token - The JWT authentication token.
  Future<void> authenticate(String token) {
    return _wsService.rpc('authenticate', [token]);
  }

  /// Kill a specific query.
  /// @param query - The query to kill.
  Future<void> kill(String query) {
    return _wsService.rpc('kill', [query]);
  }

  /// Assigns a value as a parameter for this connection.
  /// @param key - Specifies the name of the variable.
  /// @param val - Assigns the value to the variable name.
  Future<String> let(String key, String val) async {
    return (await _wsService.rpc('let', [key, val])) as String;
  }

  /// Creates a record in the database.
  /// @param thing - The table name or the specific record ID to create.
  /// @param data - The document / record data to insert (should json encodable object or Class has toJson method).
  Future<Object?> create(String thing, dynamic data) async {
    try {
      return await _wsService.rpc('create', [
        thing,
        data.toJson(),
      ]);
    } on NoSuchMethodError catch (_) {}
    try {
      return await _wsService.rpc('create', [
        thing,
        data,
      ]);
    } catch (e) {
      rethrow;
    }
  }

  /// Selects all records in a table, or a specific record, from the database.
  /// @param thing - The table name or a record ID to select.
  Future<List<T>> select<T>(String table) async {
    final res = await _wsService.rpc('select', [table]);
    if (res is List) {
      return res.cast<T>().toList();
    }
    if (res is Map) {
      return [(res as T)];
    }
    return [];
  }

  // Future<List<T>> selectTyped<T>(String table, T type) async {
  //   try {
  //     // call fromjson method from generic type
  //     var res = await _wsService.rpc('select', [table]);
  //     if (res is List) {
  //       return res.map((e) => (type as dynamic).fromJson(e)).toList()
  //           as List<T>;
  //     } else {
  //       return (type as dynamic).fromJson(res);
  //     }
  //   } on NoSuchMethodError catch (_) {
  //     throw Exception('data must be a class with fromJson() method');
  //   }
  // }

  /// Runs a set of SurrealQL statements against the database.
  /// @param query - Specifies the SurrealQL statements.
  /// @param vars - Assigns variables which can be used in the query.
  Future<Object?> query(
    String query, [
    Map<String, Object?>? vars,
  ]) async {
    return await _wsService.rpc('query', [
      query,
      if (vars != null) vars,
    ]);
  }

  /// Updates all records in a table, or a specific record, in the database.
  ///
  /// ***NOTE: This function replaces the current document / record data with the specified data.***
  /// @param thing - The table name or the specific record ID to update.
  /// @param data - The document / record data to insert.
  Future<Object?> update(
    String thing, [
    Object? data,
  ]) {
    return _wsService.rpc('update', [thing, data]);
  }

  /// Modifies all records in a table, or a specific record, in the database.
  ///
  /// ***NOTE: This function merges the current document / record data with the specified data.***
  /// @param thing - The table name or the specific record ID to change.
  /// @param data - The document / record data to insert.
  Future<Object?> change(
    String thing, [
    Object? data,
  ]) {
    return _wsService.rpc('update', [thing, data]);
  }

  /// Applies JSON Patch changes to all records, or a specific record, in the database.
  ///
  /// ***NOTE: This function patches the current document / record data with the specified JSON Patch data.***
  /// @param thing - The table name or the specific record ID to modify.
  /// @param data - The JSON Patch data with which to modify the records.
  Future<void> modify(
    String thing, [
    Object? data,
  ]) {
    return _wsService.rpc('modify', [thing, data]);
  }

  /// Deletes all records in a table, or a specific record, from the database
  /// [thing] is the table name or the record id
  Future<void> delete(String thing) {
    return _wsService.rpc('delete', [thing]);
  }

  /// Subscribe to a table
  Future<Object?> live(
    String query, [
    Map<String, Object?>? vars,
  ]) async {
    return await _wsService.rpc('live', [
      query,
      if (vars != null) vars,
    ]);
  }
}
