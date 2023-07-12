// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:surrealdb/src/common/constants.dart';
import 'package:surrealdb/src/common/models.dart';
import 'package:surrealdb/src/event_emitter.dart';
import 'package:surrealdb/src/utils.dart';
import 'package:surrealdb/surrealdb.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

typedef WsFunctionParam = Map<String, dynamic>;
typedef WsFunction = void Function(WsFunctionParam);

class WSService {
  WSService(this.url, this.options);
  final String url;
  final SurrealDBOptions options;

  WebSocketChannel? _ws;
  final _methodBus = EventEmitter<String>();

  final _liveQueue = EventEmitter<String>();
  final Map<String, List<LiveQueryResponse>> _unProcessedLiveQueue = {};

  var _shouldReconnect = false;

  var _reconnectDuration = const Duration(milliseconds: 100);

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
  }

  Future<void> reconnect() async {
    await _ws?.sink.close(status.normalClosure);
  }

  Future<void> onDone() async {
    // Socket closed
    _liveQueue.listeners.forEach((key, value) {
      _liveQueue.emit(
          key,
          LiveQueryResponse(
            action: LiveQueryAction.close,
            detail: LiveQueryClosureReason.socketClosed,
          ));
    });

    _liveQueue.removeAllListener();

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
            'result': {
              'id': dynamic _,
              'action': String _,
              'result': Map<String, dynamic> _,
            }
          }) {
        _handleLiveBatch(data['result'] as Map<String, dynamic>);
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

  void _handleLiveBatch(Map<String, dynamic> data) {
    try {
      if (data
          case {
            'id': final dynamic id,
            'action': final String action,
            'result': Object? result,
          }) {
        result ??= {};
        final uuid = parseUuid(id);
        if (_liveQueue.listeners.containsKey(uuid)) {
          if (result is List) {
            result.map(
              (e) => _liveQueue.emit(
                uuid,
                LiveQueryResponse(
                    action: LiveQueryAction.fromText(action), result: e),
              ),
            );
          } else {
            _liveQueue.emit(
              uuid,
              LiveQueryResponse(
                  action: LiveQueryAction.fromText(action), result: result),
            );
          }
        } else {
          _unProcessedLiveQueue.putIfAbsent(uuid, () => []);
          _unProcessedLiveQueue[id]!.add(
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

  void listenLive(
    String queryUuid,
    void Function(LiveQueryResponse) cb,
  ) {
    _liveQueue.addListener(
        queryUuid, (dynamic e) => cb(e as LiveQueryResponse));
    if (_unProcessedLiveQueue.containsKey(queryUuid)) {
      _unProcessedLiveQueue[queryUuid]!
          .map((e) => _liveQueue.emit(queryUuid, e));
      _unProcessedLiveQueue.remove(queryUuid);
    }
  }

  void kill(String queryUuid) {
    _liveQueue
      ..emit(
        queryUuid,
        LiveQueryResponse(
          action: LiveQueryAction.close,
          detail: LiveQueryClosureReason.queryKilled,
        ),
      )
      ..removeListenersByEvent(queryUuid);
  }
}
