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
  Future<Object?> signin({
    String? user,
    String? pass,
    String? namespace,
    String? database,
    String? access,
    Map<String, Object?>? extra,
  }) {
    final object = <String, Object?>{
      if (user != null) 'user': user,
      if (pass != null) 'pass': pass,
      if (namespace != null) 'NS': namespace,
      if (database != null) 'DB': database,
      if (access != null) 'AC': access,
      if (extra != null) ...extra
    };

    return _wsService.rpc(Methods.signin, [object]);
  }

  /// Invalidates the authentication for the current connection.
  Future<void> invalidate() {
    return _wsService.rpc(Methods.invalidate);
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
