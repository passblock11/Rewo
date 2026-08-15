import 'dart:io';

/// Performance tuning — enabled by default in production.
class PerformanceConfig {
  const PerformanceConfig({
    this.enabled = true,
    this.lazyBodyParsing = true,
    this.precompileMiddleware = true,
    this.isolateWorkers = 0,
    this.maxConnections = 10000,
    this.idleTimeoutSeconds = 120,
    this.autoCompress = true,
  });

  factory PerformanceConfig.turbo() => PerformanceConfig(
        enabled: true,
        lazyBodyParsing: true,
        precompileMiddleware: true,
        isolateWorkers: Platform.numberOfProcessors,
        maxConnections: 10000,
        idleTimeoutSeconds: 120,
        autoCompress: true,
      );

  final bool enabled;
  final bool lazyBodyParsing;
  final bool precompileMiddleware;
  final int isolateWorkers;
  final int maxConnections;
  final int idleTimeoutSeconds;
  final bool autoCompress;
}
