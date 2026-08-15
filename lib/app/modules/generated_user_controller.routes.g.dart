part of '../modules/users_module.dart';

mixin $GeneratedUserControllerRoutes on RestController {
  @override
  String get basePath => '/api/v2/users';

  @override
  void registerRoutes(RouteRegistrar registrar) {
    final c = this as GeneratedUserController;
    registrar.get('/', c.list);
    registrar.get('/:id', c.get);
    registrar.post('/', c.create, statusCode: 201);
  }
}
