import 'package:build/build.dart';

import 'route_generator.dart' as gen;

/// build_runner entry — configured in build.yaml.
Builder routeBuilder(BuilderOptions options) => gen.routeBuilder(options);
