import 'package:surrealdb/src/common/constants.dart';

class RpcResponse {
  RpcResponse(this.data, this.error);
  final Object data;
  final Object? error;

  @override
  String toString() => 'RpcResponse{data: $data, error: $error}';
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
  String toString() =>
      'LiveQueryResponse{action: $action, result: $result, detail: $detail}';
}
