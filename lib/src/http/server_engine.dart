/// Server engine selection.
enum ServerEngine {
  /// Shelf + shelf_router (default, compatible).
  shelf,

  /// Direct dart:io HttpServer — ~1.5× faster.
  native,

  /// HTTP/2 over TLS — multiplexed streams.
  http2,
}
