import 'package:uuid/uuid.dart';

Future<void> sleep(Duration duration) => Future.delayed(duration);

String parseUuid(dynamic input) {
  if (input is List) {
    return Uuid.unparse(List<int>.from(input));
  } else if (input is String) {
    return input;
  } else {
    throw Exception('Uuid parsing failed');
  }
}
