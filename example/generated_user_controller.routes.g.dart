// GENERATED CODE - dart run build_runner build

part of 'generated_user_controller.dart';

mixin $GeneratedUserControllerRoutes on RestController {
  @override
  String get basePath => '/api/v2/users';

  @override
  void registerRoutes(RouteRegistrar r) {
    final c = this as GeneratedUserController;
    r.get('/', c.list);
    r.get('/:id', c.get);
    r.post('/', c.create, statusCode: 201);
  }
}
