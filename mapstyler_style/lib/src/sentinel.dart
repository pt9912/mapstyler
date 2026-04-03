/// Sentinel for detecting omitted parameters in `copyWith` methods.
///
/// Package-internal — not exported from the public API.
///
/// When a `copyWith` parameter has a default of [absent], the method can
/// distinguish "not provided" (keep current value) from an explicit
/// `null` (clear the value).  The tradeoff is that parameter types must
/// be declared as `Object?`, so type errors surface at runtime rather
/// than at compile time.
const absent = Absent();

/// Marker type for the [absent] sentinel.  See [absent] for details.
class Absent {
  const Absent();
}
