/// Demo task CRUD routes with pagination.
library tasks_module;

import 'package:rewo/rewo.dart';

import '../models/task_models.dart';

/// Registers in-memory task APIs for the demo app.
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

/// Application service for task CRUD operations.
class TaskService {
  /// Creates a service backed by [repo].
  TaskService(this._repo);
  final InMemoryRepository<Task, String> _repo;

  /// Returns all tasks.
  Future<List<Task>> all() => _repo.findAll();

  /// Returns a task by [id] or throws [NotFoundException].
  Future<Task> find(String id) async {
    final task = await _repo.findById(id);
    if (task == null) throw NotFoundException('Task $id not found');
    return task;
  }

  /// Validates and creates a task from [req].
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

  /// Toggles the `done` flag for a task [id].
  Future<Task> toggle(String id) async {
    final task = await find(id);
    return _repo.save(task.copyWith(done: !task.done));
  }

  /// Deletes a task by [id].
  Future<bool> delete(String id) => _repo.deleteById(id);
}

/// REST controller for `/api/tasks`.
class TaskController extends RestController {
  /// Creates a controller backed by [tasks].
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
    return Page(
            items: slice, page: page.page, limit: page.limit, total: all.length)
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
