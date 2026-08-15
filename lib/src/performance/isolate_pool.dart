import 'dart:async';
import 'dart:io';
import 'dart:isolate';

typedef ComputeCallback<M, R> = R Function(M message);

/// Shared isolate pool — reuses workers instead of spawning per task.
class IsolatePool {
  IsolatePool({int? workers})
      : _workerCount = workers ?? Platform.numberOfProcessors.clamp(1, 8) {
    for (var i = 0; i < _workerCount; i++) {
      _spawn();
    }
  }

  final int _workerCount;
  final List<_IsolateWorker> _workers = [];
  final List<_QueuedTask> _queue = [];
  int _taskId = 0;
  int _roundRobin = 0;
  bool _closed = false;

  Future<void> _spawn() async {
    final worker = _IsolateWorker(onResult: _onResult);
    await worker.start();
    _workers.add(worker);
    _pump();
  }

  final Map<int, Completer<dynamic>> _pending = {};

  void _onResult(_ResultMessage message) {
    final completer = _pending.remove(message.id);
    if (completer == null) return;
    if (message.error != null) {
      completer.completeError(message.error!, message.stack);
    } else {
      completer.complete(message.value);
    }
    _pump();
  }

  Future<R> run<M, R>(ComputeCallback<M, R> callback, M message) {
    if (_closed) {
      return Future.error(StateError('IsolatePool is closed'));
    }
    final id = _taskId++;
    final completer = Completer<R>();
    _pending[id] = completer as Completer<dynamic>;
    _queue.add(_QueuedTask(id, callback, message));
    _pump();
    return completer.future;
  }

  void _pump() {
    while (_queue.isNotEmpty) {
      _IsolateWorker? worker;
      for (var i = 0; i < _workers.length; i++) {
        final idx = (_roundRobin + i) % _workers.length;
        if (!_workers[idx].busy) {
          worker = _workers[idx];
          _roundRobin = idx + 1;
          break;
        }
      }
      if (worker == null) return;
      worker.execute(_queue.removeAt(0));
    }
  }

  Future<void> close() async {
    _closed = true;
    await Future.wait(_workers.map((w) => w.close()));
    _workers.clear();
  }
}

class _QueuedTask {
  _QueuedTask(this.id, this.callback, this.message);
  final int id;
  final Function callback;
  final dynamic message;
}

class _IsolateWorker {
  _IsolateWorker({required this.onResult});

  final void Function(_ResultMessage message) onResult;
  SendPort? _sendPort;
  Isolate? _isolate;
  final _receivePort = ReceivePort();
  bool busy = false;

  Future<void> start() async {
    final initPort = ReceivePort();
    _isolate = await Isolate.spawn(_entry, initPort.sendPort);
    _sendPort = await initPort.first as SendPort;
    initPort.close();

    _receivePort.listen((message) {
      if (message is _ResultMessage) {
        busy = false;
        onResult(message);
      }
    });
  }

  void execute(_QueuedTask task) {
    busy = true;
    _sendPort!.send(_TaskMessage(
      id: task.id,
      replyPort: _receivePort.sendPort,
      callback: task.callback,
      message: task.message,
    ));
  }

  Future<void> close() async {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort.close();
  }

  static void _entry(SendPort mainSendPort) {
    final port = ReceivePort();
    mainSendPort.send(port.sendPort);
    port.listen((message) {
      if (message is! _TaskMessage) return;
      try {
        final result = Function.apply(message.callback, [message.message]);
        message.replyPort.send(_ResultMessage(id: message.id, value: result));
      } catch (e, st) {
        message.replyPort.send(_ResultMessage(id: message.id, error: e, stack: st));
      }
    });
  }
}

class _TaskMessage {
  _TaskMessage({
    required this.id,
    required this.replyPort,
    required this.callback,
    required this.message,
  });
  final int id;
  final SendPort replyPort;
  final Function callback;
  final dynamic message;
}

class _ResultMessage {
  _ResultMessage({required this.id, this.value, this.error, this.stack});
  final int id;
  final dynamic value;
  final Object? error;
  final StackTrace? stack;
}

IsolatePool? _sharedPool;

IsolatePool sharedIsolatePool({int workers = 4}) {
  return _sharedPool ??= IsolatePool(workers: workers);
}

Future<R> computePooled<M, R>(ComputeCallback<M, R> callback, M message) {
  return sharedIsolatePool().run(callback, message);
}
