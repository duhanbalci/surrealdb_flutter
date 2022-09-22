class EventEmitter {
  Map<String, List<Function>> listeners = {};
  Map<String, List<Function>> willBeDeleted = {};

  addListener<T>(event, Function(T) fn) {
    listeners[event] = listeners[event] ?? [];
    listeners[event]!.add(fn);
  }

  on<T>(event, Function(T) fn) {
    addListener(event, fn);
  }

  once<T>(event, Function(T) fn) {
    listeners[event] = listeners[event] ?? [];
    dynamic onceWrapper;
    onceWrapper = (T data) {
      fn(data);
      willBeDeleted[event] = willBeDeleted[event] ?? [];
      willBeDeleted[event]!.add(onceWrapper);
    };
    listeners[event]!.add(onceWrapper);
  }

  removeListener(event, fn) {
    var list = listeners[event];
    if (list == null) return;

    list.removeWhere((e) => e == fn);
    if (list.isEmpty) {
      listeners.remove(event);
    }
  }

  off(event, fn) {
    removeListener(event, fn);
  }

  emit(event, data) {
    var fns = listeners[event];
    if (fns == null) return;
    for (var f in fns) {
      try {
        f(data);
      } catch (e) {
        rethrow;
      }
    }
    processWillBeDeleted();
  }

  processWillBeDeleted() {
    willBeDeleted.forEach((event, fns) {
      for (var fn in fns) {
        removeListener(event, fn);
      }
    });
    willBeDeleted.clear();
  }

  void removeAllListener() {
    listeners.clear();
  }

  void removeListenersByEvent(String event) {
    var lis = listeners[event];
    if (lis == null) return;
    lis.clear();
  }
}
