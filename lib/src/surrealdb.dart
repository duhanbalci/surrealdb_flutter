import 'package:surrealdb/src/common/types.dart';
import 'package:surrealdb/src/live_query.dart';
import 'package:surrealdb/src/pinger.dart';
import 'package:surrealdb/src/ws.dart';
import 'package:surrealdb/surrealdb.dart';

class SurrealDB {
  SurrealDB(
    this.url, {
    this.token,
    this.options = const SurrealDBOptions(),
  }) {
    _wsService = WSService(url, options);
  }
  final String url;
  final String? token;

  Pinger? _pinger;
  late final WSService _wsService;
  final SurrealDBOptions options;

  /// Connects to a local or remote database endpoint.
  void connect() {
    try {
      _wsService.connect();
      // _pinger = Pinger(const Duration(seconds: 30));
      _wsService.waitConnect.then((value) => _pinger?.start(ping));
      if (token != null) authenticate(token!);
    } catch (e) {
      rethrow;
    }
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
    return _wsService.rpc(Methods.use, [ns, db]);
  }

  /// Retreive info about the current Surreal instance
  /// @return Returns nothing!
  Future<Object?> info() {
    return _wsService.rpc(Methods.info);
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
    final object = <String, Object?>{
      if (user != null) 'user': user,
      if (pass != null) 'pass': pass,
      if (namespace != null) 'NS': namespace,
      if (database != null) 'DB': database,
      if (scope != null) 'SC': scope,
      if (extra != null) ...extra
    };

    return (await _wsService.rpc(Methods.signup, [object]) ?? '') as String;
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
    final object = <String, Object?>{
      if (user != null) 'user': user,
      if (pass != null) 'pass': pass,
      if (namespace != null) 'NS': namespace,
      if (database != null) 'DB': database,
      if (scope != null) 'SC': scope,
      if (extra != null) ...extra
    };

    return _wsService.rpc(Methods.signin, [object]);
  }

  /// Invalidates the authentication for the current connection.
  Future<void> invalidate() {
    return _wsService.rpc(Methods.invalidate);
  }

  /// Authenticates the current connection with a JWT token.
  /// @param token - The JWT authentication token.
  Future<void> authenticate(String token) {
    return _wsService.rpc(Methods.authenticate, [token]);
  }

  /// Assigns a value as a parameter for this connection.
  /// @param key - Specifies the name of the variable.
  /// @param val - Assigns the value to the variable name.
  Future<String> let(String key, String val) async {
    return (await _wsService.rpc(Methods.let, [key, val]) ?? '') as String;
  }

  /// Creates a record in the database.
  /// @param thing - The table name or the specific record ID to create.
  /// @param data - The document / record data to insert (should json encodable object or Class has toJson method).
  Future<Object?> create(String thing, dynamic data) async {
    try {
      return await _wsService.rpc(Methods.create, [
        thing,
        // ignore: avoid_dynamic_calls
        data.toJson(),
      ]);
    } catch (e) {
      if (e is! NoSuchMethodError) {
        rethrow;
      }
    }
    try {
      return await _wsService.rpc(Methods.create, [
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
    final res = await _wsService.rpc(Methods.select, [table]);
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
  //     var res = await _wsService.rpc(Method.select, [table]);
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
    try {
      final result = await _wsService.rpc(Methods.query, [
        query,
        if (vars != null) vars,
      ]) as List?;

      result?.forEach((element) {
        if (element case {'status': 'ERR'}) {
          throw Exception(element['detail'] ?? element['result']);
        }
      });

      return result;
    } catch (e) {
      rethrow;
    }
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
    return _wsService.rpc(Methods.update, [thing, data]);
  }

  /// Modifies all records in a table, or a specific record, in the database.
  ///
  /// ***NOTE: This function merges the current document / record data with the specified data.***
  /// @param thing - The table name or the specific record ID to change.
  /// @param data - The document / record data to insert.
  Future<void> merge(
    String thing, [
    Object? data,
  ]) {
    return _wsService.rpc(Methods.merge, [thing, data]);
  }

  /// Applies JSON Patch changes to all records, or a specific record, in the database.
  ///
  /// ***NOTE: This function patches the current document / record data with the specified JSON Patch data.***
  /// @param thing - The table name or the specific record ID to modify.
  /// @param data - The JSON Patch data with which to modify the records.
  Future<Object?> patch(
    String thing, [
    List<Patch>? data,
  ]) {
    return _wsService.rpc(Methods.patch, [thing, data]);
  }

  /// Deletes all records in a table, or a specific record, from the database
  /// [thing] is the table name or the record id
  Future<void> delete(String thing) {
    return _wsService.rpc(Methods.delete, [thing]);
  }

  /// Subscribe to a table
  Future<LiveQuery> liveTable(
    String table, [
    Map<String, Object?>? vars,
  ]) async {
    final uuid = await _wsService.rpc(Methods.live, [
      table,
      if (vars != null) vars,
    ]);

    return _wsService.listenLiveStream(parseUuid(uuid));
  }

  /// Subscribe to a query
  Future<LiveQuery> liveQuery(
    String query, [
    Map<String, Object?>? vars,
  ]) async {
    try {
      final result = await _wsService.rpc(Methods.query, [
        query,
        if (vars != null) vars,
      ]);

      final uuid =
          ((result as List?)?.firstOrNull as Map<String, Object?>)['result'];

      return _wsService.listenLiveStream(parseUuid(uuid));
    } catch (err) {
      rethrow;
    }
  }
}
