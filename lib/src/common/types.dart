sealed class Patch {
  const Patch(this.path, this.op);

  final String path;
  final String op;

  Map<String, dynamic> toJson();

  static Patch fromJson(Map<String, dynamic> json) {
    final op = json['op'] as String;
    final patch = switch (op) {
      'add' => AddPatch.fromJson(json),
      'remove' => RemovePatch.fromJson(json),
      'replace' => ReplacePatch.fromJson(json),
      'move' => MovePatch.fromJson(json),
      'copy' => CopyPatch.fromJson(json),
      'test' => TestPatch.fromJson(json),
      _ => throw Exception('Invalid JSON'),
    };

    return patch;
  }
}

class AddPatch extends Patch {
  const AddPatch(String path, this.value) : super(path, 'add');

  final dynamic value;

  @override
  Map<String, dynamic> toJson() {
    return {
      'op': op,
      'path': path,
      'value': value,
    };
  }

  static AddPatch fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'op': 'add',
          'path': final String path,
          'value': final Object value
        }) {
      return AddPatch(path, value);
    }

    throw Exception('Invalid JSON');
  }
}

class RemovePatch extends Patch {
  const RemovePatch(String path) : super(path, 'remove');

  @override
  Map<String, dynamic> toJson() {
    return {
      'op': op,
      'path': path,
    };
  }

  static RemovePatch fromJson(Map<String, dynamic> json) {
    if (json case {'op': 'remove', 'path': final String path}) {
      return RemovePatch(path);
    }

    throw Exception('Invalid JSON');
  }
}

class ReplacePatch extends Patch {
  const ReplacePatch(String path, this.value) : super(path, 'replace');

  final dynamic value;

  @override
  Map<String, dynamic> toJson() {
    return {
      'op': op,
      'path': path,
      'value': value,
    };
  }

  static ReplacePatch fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'op': 'replace',
          'path': final String path,
          'value': final Object value
        }) {
      return ReplacePatch(path, value);
    }

    throw Exception('Invalid JSON');
  }
}

class CopyPatch extends Patch {
  const CopyPatch(String path, this.from) : super(path, 'copy');

  final String from;

  @override
  Map<String, dynamic> toJson() {
    return {
      'op': op,
      'path': path,
      'from': from,
    };
  }

  static CopyPatch fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'op': 'copy',
          'path': final String path,
          'from': final String from
        }) {
      return CopyPatch(path, from);
    }

    throw Exception('Invalid JSON');
  }
}

class MovePatch extends Patch {
  const MovePatch(String path, this.from) : super(path, 'move');

  final String from;

  @override
  Map<String, dynamic> toJson() {
    return {
      'op': op,
      'path': path,
      'from': from,
    };
  }

  static MovePatch fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'op': 'move',
          'path': final String path,
          'from': final String from
        }) {
      return MovePatch(path, from);
    }

    throw Exception('Invalid JSON');
  }
}

class TestPatch extends Patch {
  const TestPatch(String path, this.value) : super(path, 'test');

  final dynamic value;

  @override
  Map<String, dynamic> toJson() {
    return {
      'op': op,
      'path': path,
      'value': value,
    };
  }

  static TestPatch fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'op': 'test',
          'path': final String path,
          'value': final Object value
        }) {
      return TestPatch(path, value);
    }

    throw Exception('Invalid JSON');
  }
}
