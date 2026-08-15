/// Generic in-memory repository with CRUD operations.
abstract class Repository<T, ID> {
  Future<T?> findById(ID id);
  Future<List<T>> findAll();
  Future<T> save(T entity);
  Future<bool> deleteById(ID id);
}

class InMemoryRepository<T, ID> implements Repository<T, ID> {
  InMemoryRepository({
    required this.getId,
    Map<ID, T>? items,
  }) : items = items ?? {};

  final ID Function(T item) getId;
  final Map<ID, T> items;

  @override
  Future<T?> findById(ID id) async => items[id];

  @override
  Future<List<T>> findAll() async => items.values.toList();

  @override
  Future<T> save(T entity) async {
    items[getId(entity)] = entity;
    return entity;
  }

  @override
  Future<bool> deleteById(ID id) async => items.remove(id) != null;
}
