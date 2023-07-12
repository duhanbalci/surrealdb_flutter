import 'package:surrealdb/src/common/constants.dart';

class RpcResponse {
  RpcResponse(this.data, this.error);
  final Object data;
  final Object? error;
}

class LiveQueryResponse {
  LiveQueryResponse({
    required this.action,
    this.result,
    this.detail,
  });
  final LiveQueryAction action;
  final Object? result;
  final LiveQueryClosureReason? detail;

  @override
  String toString() {
    return 'LiveQueryResponse{action: $action, result: $result, detail: $detail}';
  }
}

// class UnprocessedLiveQueryResponse extends LiveQueryResponse {
//   UnprocessedLiveQueryResponse({
//     required super.action,
//     required this.query,
//     super.detail,
//     super.result,
//   });

//   final String query;
// }
