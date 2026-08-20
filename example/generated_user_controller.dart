import 'package:rewo/rewo.dart';

part 'generated_user_controller.routes.g.dart';

/// Example of build_runner route codegen — run: dart run build_runner build
@Controller('/api/v2/users')
class GeneratedUserController extends RestController
    with $GeneratedUserControllerRoutes {
  @Get('/')
  Future<Map<String, dynamic>> list(RequestContext ctx) async => {'users': []};

  @Get('/:id')
  Future<Map<String, dynamic>> get(RequestContext ctx) async =>
      {'id': ctx.param('id')};

  @Post('/')
  @StatusCode(201)
  Future<Map<String, dynamic>> create(RequestContext ctx) async =>
      {'created': true};
}
