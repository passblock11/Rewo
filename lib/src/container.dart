typedef Factory<T> = T Function(ServiceContainer container);

/// Simple constructor-based dependency injection container.
class ServiceContainer {
  ServiceContainer();

  final Map<Type, _Binding> _bindings = {};
  final Map<Type, dynamic> _singletons = {};

  void registerSingleton<T>(T instance) {
    _singletons[T] = instance;
    _bindings[T] = _Binding.singleton(instance);
  }

  void registerFactory<T>(Factory<T> factory) {
    _bindings[T] = _Binding.factory(factory);
  }

  void registerLazySingleton<T>(Factory<T> factory) {
    _bindings[T] = _Binding.lazy(factory);
  }

  T resolve<T>() {
    final binding = _bindings[T];
    if (binding == null) {
      throw StateError('No binding registered for type $T');
    }
    return binding.resolve<T>(this);
  }

  bool isRegistered<T>() => _bindings.containsKey(T);

  List<T> resolveAll<T>() {
    return _bindings.entries
        .where((e) => e.value.matches<T>())
        .map((e) => e.value.resolve<T>(this))
        .toList();
  }
}

class _Binding {
  _Binding._(this.kind, {this.instance, this.factory});

  factory _Binding.singleton(dynamic instance) =>
      _Binding._(_BindingKind.singleton, instance: instance);

  factory _Binding.factory(Factory factory) =>
      _Binding._(_BindingKind.factory, factory: factory);

  factory _Binding.lazy(Factory factory) =>
      _Binding._(_BindingKind.lazy, factory: factory);

  final _BindingKind kind;
  final dynamic instance;
  final Factory? factory;
  dynamic _lazyInstance;

  bool matches<T>() {
    if (kind == _BindingKind.singleton) {
      return instance.runtimeType == T;
    }
    return false;
  }

  T resolve<T>(ServiceContainer container) {
    switch (kind) {
      case _BindingKind.singleton:
        return instance as T;
      case _BindingKind.factory:
        return factory!(container) as T;
      case _BindingKind.lazy:
        _lazyInstance ??= factory!(container);
        return _lazyInstance as T;
    }
  }
}

enum _BindingKind { singleton, factory, lazy }
