import 'dart:async';

import 'package:surrealdb/surrealdb.dart';

typedef KillFunc = void Function();

class LiveQuery {
  LiveQuery(this.controller, this._kill);

  final StreamController<LiveQueryResponse> controller;
  Stream<LiveQueryResponse> get stream => controller.stream;
  bool get isClosed => controller.isClosed;
  late final KillFunc _kill;

  Future<void> kill() async {
    _kill();
    unawaited(controller.close());
  }
}
