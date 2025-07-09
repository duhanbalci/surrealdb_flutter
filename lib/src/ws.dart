// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:surrealdb/src/event_emitter.dart';
import 'package:surrealdb/src/live_query.dart';
import 'package:surrealdb/surrealdb.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

typedef WsFunctionParam = Map<String, dynamic>;
typedef WsFunction = void Function(WsFunctionParam);

typedef Middleware = Future<Object?> Function(
  String method,
  List<Object?> params,
  Future<Object?> Function() next,
);

class WSService {
  WSService(this.url, this.options);
  final String url;
  final SurrealDBOptions options;

  WebSocketChannel? _ws;
  final _methodBus = EventEmitter<String>();
  final Map<String, StreamController<LiveQueryResponse>> _liveQueryStreams = {};

  var _shouldReconnect = false;

  var _reconnectDuration = const Duration(milliseconds: 100);

  final List<Middleware> _middlewares = [];

  void setMiddlewares(List<Middleware> middlewares) {
    _middlewares
      ..clear()
      ..addAll(middlewares);
  }

  Future<void> connect() async {
    _shouldReconnect = true;
    try {
      _ws = WebSocketChannel.connect(Uri.parse(url))
        ..stream
            .where((event) => event is String)
            .map((event) => jsonDecode(event as String) as Map<String, dynamic>)
            .listen(
              _handleMessage,
              cancelOnError: true,
              onDone: onDone,
              onError: (_) => onDone,
            );
    } catch (e) {
      rethrow;
    } finally {
      _reconnectDuration = const Duration(milliseconds: 100);
    }
  }

  Future<void> get waitConnect => _ws!.ready;

  void disconnect() {
    _shouldReconnect = false;
    _ws?.sink.close(status.normalClosure);
    _ws = null;
    _methodBus.removeAllListener();
  }

  Future<void> reconnect() async {
    await _ws?.sink.close(status.normalClosure);
  }

  Future<void> onDone() async {
    // close all live query streams
    await Future.wait(_liveQueryStreams.values.map((c) => c.close()));
    // clear all live query streams
    _liveQueryStreams.clear();
    _methodBus.removeAllListener();

    if (!_shouldReconnect) return;

    await sleep(_reconnectDuration);

    _reconnectDuration = _reconnectDuration * 2;
    if (_reconnectDuration > const Duration(seconds: 10)) {
      _reconnectDuration = const Duration(seconds: 10);
    }

    try {
      await connect();
    } catch (e) {
      await onDone();
    }
  }

  var _serial = 1;
  String getNextId() {
    return (_serial++).toString();
  }

  Future<Object?> rpc(
    String method, [
    List<Object?> data = const [],
    Duration? timeout,
  ]) async {
    final ws = _ws;

    if (ws == null) {
      throw Exception('websocket not connected');
    }

    // Function to execute the actual RPC call without middleware
    Future<Object?> executeActualRpc() async {
      // Re-capture current WebSocket to avoid using stale reference
      final currentWs = _ws;
      if (currentWs == null) {
        throw Exception('websocket not connected');
      }

      // Check if WebSocket sink is closed
      if (currentWs.closeCode != null) {
        throw Exception('websocket connection closed');
      }

      final id = getNextId();
      final completer = Completer<Object?>();

      currentWs.sink.add(
        jsonEncode(
          {
            'method': method,
            'id': id,
            'params': data,
          },
        ),
      );

      if (timeout != Duration.zero) {
        Future.delayed(
          options.timeoutDuration,
          () {
            if (completer.isCompleted) return;
            completer.completeError(TimeoutException('timeout', timeout));
          },
        );
      }

      try {
        _methodBus.once<RpcResponse>(id, (rpcResponse) {
          if (completer.isCompleted) return;
          if (rpcResponse.error != null) {
            completer.completeError(rpcResponse.error!);
          } else {
            completer.complete(rpcResponse.data);
          }
        });
      } catch (e) {
        // If we can't add listener, the connection is probably closed
        completer.completeError(Exception('websocket connection closed: $e'));
      }

      return completer.future;
    }

    // If there are no middlewares, just execute the RPC call directly
    if (_middlewares.isEmpty) {
      return executeActualRpc();
    }

    // Build the middleware chain
    var index = 0;

    Future<Object?> executeMiddlewareChain() async {
      if (index < _middlewares.length) {
        final middleware = _middlewares[index++];
        // Execute the middleware and pass the next middleware in the chain
        return middleware(method, data, executeMiddlewareChain);
      } else {
        // All middlewares executed, perform the actual RPC call
        return executeActualRpc();
      }
    }

    // Start executing the middleware chain
    return executeMiddlewareChain();
  }

  Future<void> _handleMessage(Map<String, dynamic> data) async {
    try {
      if (data
          case {
            'result': {
              'id': dynamic _,
              'action': String _,
              'result': Object? _,
            }
          }) {
        _handleLiveMessage(data['result'] as Map<String, dynamic>);
      } else if (data
          case {
            'id': final String id,
            'result': Object? result,
          }) {
        result ??= {};
        _methodBus.emit(id, RpcResponse(result, data['error']));
      } else if (data
          case {
            'id': final String id,
            'error': Object? error,
          }) {
        error ??= {};
        _methodBus.emit(id, RpcResponse(error, error));
      } else {
        throw Exception('invalid message');
      }
    } catch (_) {
      rethrow;
    }
  }

  void _handleLiveMessage(Object? data) {
    try {
      if (data
          case {
            'id': final dynamic id,
            'action': final String action,
            'result': Object? result,
          }) {
        result ??= {};
        final uuid = parseUuid(id);
        final results = result is List ? result : [result];
        for (final result in results) {
          _liveQueryStreams[uuid]?.add(
            LiveQueryResponse(
              action: LiveQueryAction.fromText(action),
              result: result,
            ),
          );
        }
      } else {
        throw Exception('invalid live message');
      }
    } catch (_) {
      rethrow;
    }
  }

  LiveQuery listenLiveStream(String uuid) {
    final hasKey = _liveQueryStreams.containsKey(uuid);

    if (!hasKey) {
      final streamController = StreamController<LiveQueryResponse>(
        onCancel: () {
          rpc(Methods.kill, [uuid]);
          _liveQueryStreams.remove(uuid);
        },
      );
      _liveQueryStreams[uuid] = streamController;
      return LiveQuery(streamController, () {
        rpc(Methods.kill, [uuid]);
        _liveQueryStreams.remove(uuid);
      });
    } else {
      return LiveQuery(_liveQueryStreams[uuid]!, () {
        rpc(Methods.kill, [uuid]);
        _liveQueryStreams.remove(uuid);
      });
    }
  }
}
