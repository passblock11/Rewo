import 'package:rewo/rewo.dart';

import '../models/task_models.dart';

class TasksModule implements RewoModule {
  @override
  String get name => 'tasks';

  @override
  void register(Rewo app) {
    final repo = InMemoryRepository<Task, String>(getId: (t) => t.id);
    app.singleton(repo);
    app.singleton(TaskService(repo));
    app.mount(TaskController(app.container.resolve<TaskService>()));
  }
}

class TaskService {
  TaskService(this._repo);
  final InMemoryRepository<Task, String> _repo;

  Future<List<Task>> all() => _repo.findAll();

  Future<Task> find(String id) async {
    final task = await _repo.findById(id);
    if (task == null) throw NotFoundException('Task $id not found');
    return task;
  }

  Future<Task> create(CreateTaskRequest req) async {
    Validator.validateOrThrow(
      {'title': req.title},
      {'title': const ValidateRule(required: true, minLength: 1)},
    );
    return _repo.save(Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: req.title,
      description: req.description,
      done: false,
      createdAt: DateTime.now(),
    ));
  }

  Future<Task> toggle(String id) async {
    final task = await find(id);
    return _repo.save(task.copyWith(done: !task.done));
  }

  Future<bool> delete(String id) => _repo.deleteById(id);
}

class TaskController extends RestController {
  TaskController(this._tasks);
  final TaskService _tasks;

  @override
  String get basePath => '/api/tasks';

  @override
  void registerRoutes(RouteRegistrar r) {
    r.get('/', list);
    r.get('/:id', getOne);
    r.post('/', create, statusCode: 201);
    r.patch('/:id/toggle', toggle);
    r.delete('/:id', remove);
  }

  Future<Map<String, dynamic>> list(RequestContext ctx) async {
    final page = PageRequest.fromQuery(ctx.queryParameters);
    final all = await _tasks.all();
    final slice = all.skip(page.offset).take(page.limit).toList();
    return Page(items: slice, page: page.page, limit: page.limit, total: all.length)
        .toJson((t) => t.toJson());
  }

  Future<Map<String, dynamic>> getOne(RequestContext ctx) async {
    return (await _tasks.find(ctx.param('id')!)).toJson();
  }

  Future<Map<String, dynamic>> create(RequestContext ctx) async {
    final req = await ctx.bodyAs(CreateTaskRequest.fromJson);
    return (await _tasks.create(req)).toJson();
  }

  Future<Map<String, dynamic>> toggle(RequestContext ctx) async {
    return (await _tasks.toggle(ctx.param('id')!)).toJson();
  }

  Future<Map<String, dynamic>> remove(RequestContext ctx) async {
    return {'deleted': await _tasks.delete(ctx.param('id')!)};
  }
}
