import 'package:surrealdb/src/common/constants.dart';

class EventEmitter<K> {
  Map<K, List<VoidCallback<dynamic>>> listeners = {};
  Map<K, List<VoidCallback<dynamic>>> willBeDeleted = {};

  void addListener<T>(K event, VoidCallback<T> fn) {
    listeners[event] = listeners[event] ?? [];
    listeners[event]!.add(fn as VoidCallback<dynamic>);
  }

  void removeListener<T>(K event, VoidCallback<T> fn) {
    final list = listeners[event];
    if (list == null) return;

    list.removeWhere((e) => e == fn);
    if (list.isEmpty) {
      listeners.remove(event);
    }
  }

  void on<T>(K event, VoidCallback<T> fn) => addListener(event, fn);

  void off<T>(K event, VoidCallback<T> fn) => removeListener(event, fn);

  void once<T>(K event, VoidCallback<T> fn) {
    var onceWrapper = (_) {};
    onceWrapper = (dynamic data) {
      fn(data as T);
      willBeDeleted[event] = willBeDeleted[event] ?? [];
      willBeDeleted[event]!.add(onceWrapper);
    };
    addListener(event, onceWrapper);
  }

  void emit<T>(K event, T data) {
    final fns = listeners[event];
    if (fns == null) return;
    for (final f in fns) {
      try {
        f(data);
      } catch (e) {
        rethrow;
      }
    }
    processWillBeDeleted();
  }

  void processWillBeDeleted() {
    willBeDeleted
      ..forEach((event, fns) {
        for (final fn in fns) {
          removeListener(event, fn);
        }
      })
      ..clear();
  }

  void removeAllListener() {
    listeners.clear();
  }

  void removeListenersByEvent(K event) {
    listeners[event]?.clear();
  }
}
