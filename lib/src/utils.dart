import 'package:uuid/uuid.dart';

Future<void> sleep(Duration duration) => Future.delayed(duration);

String parseUuid(dynamic input) {
  return switch (input.runtimeType) {
    const (List<dynamic>) => Uuid.unparse(List<int>.from(input as List)),
    String => input,
    _ => throw Exception('Uuid parsing failed')
  } as String;
}
