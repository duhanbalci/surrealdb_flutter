class SurrealDBOptions {
  const SurrealDBOptions({
    this.timeoutDuration = const Duration(seconds: 30),
  });

  /// The [timeoutDuration] for every RPC call. Defaults to 30 seconds.
  final Duration timeoutDuration;

  SurrealDBOptions copyWith({
    Duration? timeoutDuration,
  }) =>
      SurrealDBOptions(
        timeoutDuration: timeoutDuration ?? this.timeoutDuration,
      );
}
