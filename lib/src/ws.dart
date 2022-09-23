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

  var reconnectDuration = const Duration(milliseconds: 100);

  WebSocketChannel? get ws => _ws;
  late String url;

  connect(String url) async {
    this.url = url;
    _shouldReconnect = true;
    try {
      _ws = WebSocketChannel.connect(Uri.parse(url));
      _ws!.stream.listen(
        (event) => _handleMessage(event),
        cancelOnError: true,
        onDone: onDone,
        onError: (e) {
          print('error');
          if (e is WebSocketChannelException) {
            onDone();
          } else {
            onDone();
          }
          print('got error in stream: $e');
        },
      );
      methodBus.once('connect', (_) async {
        print("ws: connected");
        _connectedCompleter.complete();
        reconnectDuration = const Duration(milliseconds: 100);
      });
    } catch (e) {
      print("ws error: $e");
    }
    var ping = await rpc('ping', [], Duration.zero);
    if (ping == true) {
      methodBus.emit('connect', {});
    }
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

  void onDone([e]) async {
    if (e != null) print(e);
    print('ws: closed');
    if (!_shouldReconnect) return;
    print("ws: reconnect after $reconnectDuration");

    await Future.delayed(reconnectDuration);

    reconnectDuration = reconnectDuration * 2;
    if (reconnectDuration > const Duration(seconds: 10)) {
      reconnectDuration = const Duration(seconds: 10);
    }

    try {
      print('ws: retry');
      await connect(url);
    } catch (e) {
      print("ws: error $e");
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
      return (completer..completeError('ws not connected')).future;
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
      Future.delayed(timeout ?? const Duration(seconds: 5), () {
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
    print(message);
    try {
      var messageDecoded = json.decode(message) as Map<String, dynamic>;

      var id = messageDecoded["id"];
      var error = messageDecoded["error"];
      Object result = messageDecoded["result"] ?? {};

      methodBus.emit(id, RpcResponse(result, error));
    } catch (e, stack) {
      print('error when _handleMessage: $e');
      print(stack);
    }
  }
}
