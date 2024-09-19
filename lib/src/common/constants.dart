typedef VoidCallback<T> = void Function(T);

class Methods {
  static const ping = 'ping';
  static const use = 'use';
  static const info = 'info';
  static const signup = 'signup';
  static const signin = 'signin';
  static const invalidate = 'invalidate';
  static const authenticate = 'authenticate';
  static const kill = 'kill';
  static const let = 'let';
  static const create = 'create';
  static const select = 'select';
  static const query = 'query';
  static const run = 'run';
  static const update = 'update';
  static const merge = 'merge';
  static const delete = 'delete';
  static const live = 'live';
  static const patch = 'patch';
}

enum LiveQueryAction {
  close('CLOSE'),
  create('CREATE'),
  update('UPDATE'),
  delete('DELETE');

  const LiveQueryAction(this.text);

  final String text;

  static LiveQueryAction fromText(String text) {
    for (final action in LiveQueryAction.values) {
      if (action.text.toLowerCase() == text.toLowerCase()) {
        return action;
      }
    }
    throw Exception('Unknown action: $text');
  }

  @override
  String toString() => text;
}

enum LiveQueryClosureReason {
  socketClosed('SOCKET_CLOSED'),
  queryKilled('QUERY_KILLED');

  const LiveQueryClosureReason(this.text);

  final String text;

  @override
  String toString() => text;
}
