import 'dart:async';
import 'dart:convert';

import 'package:surrealdb/src/event_emitter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef WsFunctionParam = Map<String, dynamic>;
typedef WsFunction = void Function(WsFunctionParam);

class RpcResponse {
  final Object data;
  final Object? error;

  RpcResponse(this.data, this.error);
}

class WSService {
  WebSocketChannel? _ws;
  final methodBus = EventEmitter();

  var _shouldReconnect = false;
  var _serial = 1;

  var _reconnectDuration = const Duration(milliseconds: 100);

  WebSocketChannel? get ws => _ws;
  late String url;
  late Duration _globalTimeoutDuration;

  connect(String url, Duration timeout) async {
    this.url = url;
    _globalTimeoutDuration = timeout;
    _shouldReconnect = true;
    try {
      _ws = WebSocketChannel.connect(Uri.parse(url));
      _ws!.stream.listen(
        (event) => _handleMessage(event),
        cancelOnError: true,
        onDone: onDone,
        onError: (e) {
          if (e is WebSocketChannelException) {
            onDone();
          } else {
            onDone();
          }
        },
      );
      methodBus.once('connect', (_) async {
        _connectedCompleter.complete();
        _reconnectDuration = const Duration(milliseconds: 100);
      });
    } catch (e) {
      rethrow;
    }
    await rpc('ping', [], Duration.zero);
    methodBus.emit('connect', {});
  }

  final _connectedCompleter = Completer<void>();
  Future<void> get waitConnect => _connectedCompleter.future;

  disconnect() {
    _shouldReconnect = false;
    _ws?.sink.close(1000, 'logout');
    _ws = null;
  }

  reconnect() async {
    _ws?.sink.close(1000, 'logout');
    // _ws = null;
  }

  void onDone() async {
    if (!_shouldReconnect) return;

    await Future.delayed(_reconnectDuration);

    _reconnectDuration = _reconnectDuration * 2;
    if (_reconnectDuration > const Duration(seconds: 10)) {
      _reconnectDuration = const Duration(seconds: 10);
    }

    try {
      await connect(url, _globalTimeoutDuration);
    } catch (e) {
      onDone();
    }
  }

  getNextId() {
    var id = _serial++;
    return id.toString();
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

    var id = getNextId();

    ws.sink.add(
      jsonEncode(
        {
          "method": method,
          "id": id,
          "params": data,
        },
      ),
    );

    if (timeout != Duration.zero) {
      Future.delayed(_globalTimeoutDuration, () {
        if (completer.isCompleted) return;
        completer.completeError('timeout');
      });
    }

    methodBus.once<RpcResponse>(id, (rpcResponse) {
      if (rpcResponse.error != null) {
        completer.completeError(rpcResponse.error!);
      } else {
        completer.complete(rpcResponse.data);
      }
    });

    return completer.future;
  }

  void _handleMessage(String message) async {
    try {
      var messageDecoded = json.decode(message) as Map<String, dynamic>;

      var id = messageDecoded["id"];
      var error = messageDecoded["error"];
      Object result = messageDecoded["result"] ?? {};

      methodBus.emit(id, RpcResponse(result, error));
    } catch (_) {
      rethrow;
    }
  }
}
