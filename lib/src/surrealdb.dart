import 'package:surrealdb/src/common/types.dart';
import 'package:surrealdb/src/pinger.dart';
import 'package:surrealdb/src/ws.dart';
import 'package:surrealdb/surrealdb.dart';

/// Type definition for middleware function
/// [method] - The method being called
/// [params] - The parameters passed to the method
/// [next] - The function to call to continue the middleware chain
typedef Middleware = Future<Object?> Function(
  String method,
  List<Object?> params,
  Future<Object?> Function() next,
);

/// SurrealDB client for Dart & Flutter
///
/// This client provides an interface to interact with SurrealDB via WebSockets.
/// It supports authentication, database operations, and middleware for request
/// manipulation.
///
/// Example usage with token refresh middleware:
/// ```dart
/// final db = SurrealDB('ws://localhost:8000');
/// db.connect();
/// await db.wait();
///
/// // Add a token refresh middleware
/// db.addMiddleware((method, params, next) async {
///   try {
///     // Try to execute the request normally
///     return await next();
///   } catch (e) {
///     // If we get an authentication error
///     if (e.toString().contains('authentication invalid')) {
///       // Refresh the token
///       final newToken = await refreshToken(); // Your token refresh logic
///
///       // Re-authenticate with the new token
///       await db.authenticate(newToken);
///
///       // Retry the original request
///       return await next();
///     }
///     // For other errors, just rethrow
///     rethrow;
///   }
/// });
///
/// // Now all requests will automatically refresh the token if needed
/// final results = await db.select('users');
/// ```
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

  /// List of middleware functions to execute before each request
  final List<Middleware> _middlewares = [];

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

  /// Pings SurrealDB instance
  Future<void> ping() async {
    await _wsService.rpc('ping');
  }

  /// Specifies or unsets the [namespace] and/or [database].
  Future<void> use(String? namespace, String? database) {
    return _wsService.rpc(
      Methods.use,
      [namespace, database],
    );
  }

  /// Retreives the record of an authenticated user.
  Future<Object?> info() {
    return _wsService.rpc(Methods.info);
  }

  /// Returns version information about the database/server.
  Future<Object?> version() {
    return _wsService.rpc(Methods.version);
  }

  /// Signs up a new user using the query defined in a record access method
  ///
  /// [user] and [pass] set the username and password for the new user.
  /// [namespace] and [database] specify the namespace and database to use.
  /// [access] specifies the access method to use.
  /// [extra] can be used to specify any additional variables used by
  /// the SIGNUP query of the record access method
  /// Returns an authenication token.
  Future<String> signup({
    String? user,
    String? pass,
    String? namespace,
    String? database,
    String? access,
    Map<String, Object?>? extra,
  }) async {
    final object = <String, Object?>{
      if (user != null) 'user': user,
      if (pass != null) 'pass': pass,
      if (namespace != null) 'NS': namespace,
      if (database != null) 'DB': database,
      if (access != null) 'AC': access,
      if (extra != null) ...extra
    };

    return (await _wsService.rpc(Methods.signup, [object]) ?? '') as String;
  }

  /// Signs in a user using the query defined in a record access method.
  ///
  /// [user] and [pass] are the username and password of the user.
  /// [namespace] and [database] specify the namespace and database to use.
  /// [access] specifies the access method to use.
  /// [extra] can be used to specify any additional variables used by
  /// the SIGNIN query of the record access method.
  /// Returns an authenication token.
  Future<String> signin({
    String? user,
    String? pass,
    String? namespace,
    String? database,
    String? access,
    Map<String, Object?>? extra,
  }) async {
    final object = <String, Object?>{
      if (user != null) 'user': user,
      if (pass != null) 'pass': pass,
      if (namespace != null) 'NS': namespace,
      if (database != null) 'DB': database,
      if (access != null) 'AC': access,
      if (extra != null) ...extra
    };

    return (await _wsService.rpc(Methods.signin, [object]) ?? '') as String;
  }

  /// Invalidates the authentication for the current connection.
  Future<void> invalidate() {
    return _wsService.rpc(Methods.invalidate);
  }

  /// Adds a middleware function to be executed before each request
  ///
  /// Middleware functions are executed in the order they are added.
  /// Each middleware function must call the next function to continue the chain.
  ///
  /// Example:
  /// ```dart
  /// db.addMiddleware((method, params, next) async {
  ///   print('Before request: $method');
  ///   final result = await next();
  ///   print('After request: $method');
  ///   return result;
  /// });
  /// ```
  void addMiddleware(Middleware middleware) {
    _middlewares.add(middleware);
    _wsService.setMiddlewares(_middlewares);
  }

  /// Authenticates the current connection with a JWT [token].
  Future<void> authenticate(String token) {
    return _wsService.rpc(Methods.authenticate, [token]);
  }

  /// Assigns a value as a parameter for this connection.
  /// Name of the parameter is [key] and the value is [val].
  Future<String> let(String key, String val) async {
    return (await _wsService.rpc(Methods.let, [key, val]) ?? '') as String;
  }

  /// Removes a variable from the current connection.
  /// The name of the variable to remove is specified in the [key] parameter.
  Future<void> unset(String key) {
    return _wsService.rpc(Methods.unset, [key]);
  }

  /// Creates a record in the database.
  ///
  /// The name of the table or record to create is specified
  /// in the [thing] parameter. The content of the record is
  /// specified in the [data] parameter (should be a json encodable object).
  /// Throws [NoSuchMethodError] if [data] is not json encodable.
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
  /// The table name or the record id is specified in the [thing] parameter.
  /// Returns a list of records.
  Future<List<T>> select<T>(String thing) async {
    final res = await _wsService.rpc(Methods.select, [thing]);
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
  /// The statements are specified in the [query] parameter.
  /// The [vars] parameter is used to pass variables to the query.
  /// Returns the result of the query.
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

  /// Executes built-in functions, custom functions,
  /// or machine learning models with optional arguments
  ///
  /// Takes a function [name] and optional [version] and [args]. When using
  /// a machine learning model, the [version] parameter is required.
  /// Returns the result of the function.
  Future<Object?> run(
    String name, [
    String? version,
    List<Object?>? args,
  ]) {
    return _wsService.rpc(Methods.run, [name, version, args]);
  }

  /// Updates all records in a table, or a specific record, in the database.
  ///
  /// The table name or the record id is specified in the [thing] parameter.
  /// The content of the record is specified in the [data] parameter.
  /// Returns the updated record.
  Future<Object?> update(
    String thing, [
    Object? data,
  ]) {
    return _wsService.rpc(Methods.update, [thing, data]);
  }

  /// Updates all records in a table, or a specific record, in the database. If
  /// the record does not exist, it is created.
  ///
  /// The table name or the record id is specified in the [thing] parameter.
  /// The content of the record is specified in the [data] parameter.
  /// Returns the updated record.
  Future<Object?> upsert(
    String thing, [
    Object? data,
  ]) {
    return _wsService.rpc(Methods.upsert, [thing, data]);
  }

  /// Relates two records with a specified relation.
  ///
  /// The records to relate are specified in the [in_] and [out] parameters.
  /// The relation table is specified in the [relation] parameter.
  /// Additional data can be passed in the [data] parameter.
  /// Returns the relation record.
  Future<Object?> relate(
    String in_,
    String relation,
    String out, [
    Object? data,
  ]) {
    return _wsService.rpc(
      Methods.relate,
      [in_, relation, out, if (data != null) data],
    );
  }

  /// Merges specified data into either
  /// all records in a table or a single record.
  ///
  /// The table name or the record id is specified in the [thing] parameter.
  /// The content of the record is specified in the [data] parameter.
  Future<void> merge(
    String thing, [
    Object? data,
  ]) {
    return _wsService.rpc(Methods.merge, [thing, data]);
  }

  /// Patches either all records in a table
  /// or a single record with specified patches.
  ///
  /// The table name or the record id is specified in the [thing] parameter.
  /// The patches to apply are specified in the [data] parameter.
  Future<Object?> patch(
    String thing, [
    List<Patch>? data,
  ]) {
    return _wsService.rpc(Methods.patch, [thing, data]);
  }

  /// Deletes all records in a table, or a specific record, from the database
  /// [thing] is the table name or the record id.
  Future<void> delete(String thing) {
    return _wsService.rpc(Methods.delete, [thing]);
  }

  /// Subscribes to a [table].
  ///
  /// Variables can be passed to the query using the [vars] parameter.
  /// Returns a [LiveQuery] object.
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

  /// Subscribes to a live [query].
  ///
  /// Variables can be passed to the query using the [vars] parameter.
  /// Returns a [LiveQuery] object.
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
