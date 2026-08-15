import 'dart:io';

import '../performance/performance_config.dart';

/// Applies HttpServer settings for high-throughput workloads.
void tuneHttpServer(HttpServer server, PerformanceConfig config) {
  if (!config.enabled) return;

  server.autoCompress = config.autoCompress;
  server.idleTimeout = Duration(seconds: config.idleTimeoutSeconds);
}
