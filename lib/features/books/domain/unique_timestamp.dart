int _lastUniqueTimestamp = 0;

/// Microseconds of [timestamp], raised past every earlier result, so
/// identifiers made within the same microsecond still differ.
int uniqueTimestamp(DateTime timestamp) {
  final candidate = timestamp.microsecondsSinceEpoch;
  _lastUniqueTimestamp = candidate > _lastUniqueTimestamp
      ? candidate
      : _lastUniqueTimestamp + 1;
  return _lastUniqueTimestamp;
}
