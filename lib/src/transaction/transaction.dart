/// Transaction manager with commit/rollback hooks.
class TransactionManager {
  TransactionManager();

  final List<Future<void> Function()> _onCommit = [];
  final List<Future<void> Function()> _onRollback = [];

  Future<T> run<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      for (final hook in _onCommit) {
        await hook();
      }
      return result;
    } catch (e) {
      for (final hook in _onRollback) {
        await hook();
      }
      rethrow;
    } finally {
      _onCommit.clear();
      _onRollback.clear();
    }
  }

  void onCommit(Future<void> Function() hook) => _onCommit.add(hook);
  void onRollback(Future<void> Function() hook) => _onRollback.add(hook);
}
