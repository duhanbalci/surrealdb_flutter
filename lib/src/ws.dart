import 'dart:async';
import 'dart:convert';

import 'package:surrealdb/src/event_emitter.dart';
import 'package:surrealdb/src/utils.dart';
import 'package:surrealdb/surrealdb.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

typedef WsFunctionParam = Map<String, dynamic>;
typedef WsFunction = void Function(WsFunctionParam);

class RpcResponse {
  RpcResponse(this.data, this.error);
  final Object data;
  final Object? error;
}

class WSService {
  WSService(this.url, this.options);
  final String url;
  final SurrealDBOptions options;

  WebSocketChannel? _ws;
  final _methodBus = EventEmitter<String>();

  var _shouldReconnect = false;

  var _reconnectDuration = const Duration(milliseconds: 100);

  Future<void> connect() async {
    _shouldReconnect = true;
    try {
      _ws = WebSocketChannel.connect(Uri.parse(url))
        ..stream
            .where((event) => event is String)
            .map((event) => jsonEncode(event) as Map<String, dynamic>)
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
  }

  Future<void> reconnect() async {
    await _ws?.sink.close(status.normalClosure);
  }

  Future<void> onDone() async {
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
  ]) {
    final completer = Completer<Object?>();

    final ws = _ws;

    if (ws == null) {
      return (completer..completeError('websocket not connected')).future;
    }

    final id = getNextId();

    ws.sink.add(
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

    _methodBus.once<RpcResponse>(id, (rpcResponse) {
      if (completer.isCompleted) return;
      if (rpcResponse.error != null) {
        completer.completeError(rpcResponse.error!);
      } else {
        completer.complete(rpcResponse.data);
      }
    });

    return completer.future;
  }

  Future<void> _handleMessage(Map<String, dynamic> data) async {
    try {
      if (data
          case {
            'id': final String id,
            'error': final Object? error,
            'result': Object? result,
          }) {
        result ??= {};
        _methodBus.emit(id, RpcResponse(result, error));
      }
    } catch (_) {
      rethrow;
    }
  }
}
