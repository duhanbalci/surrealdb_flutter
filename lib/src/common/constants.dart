typedef VoidCallback<T> = void Function(T);

class Methods {
  static const use = 'use';
  static const info = 'info';
  static const version = 'version';
  static const signup = 'signup';
  static const signin = 'signin';
  static const authenticate = 'authenticate';
  static const invalidate = 'invalidate';
  static const let = 'let';
  static const live = 'live';
  static const kill = 'kill';
  static const query = 'query';
  static const run = 'run';
  static const select = 'select';
  static const create = 'create';
  static const update = 'update';
  static const upsert = 'upsert';
  static const merge = 'merge';
  static const patch = 'patch';
  static const delete = 'delete';
  static const ping = 'ping';
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
