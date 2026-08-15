import 'dart:async';

/// Simple in-memory job queue with worker processing.
class JobQueue {
  JobQueue({this.concurrency = 2});

  final int concurrency;
  final List<_Job> _pending = [];
  int _active = 0;
  bool _running = false;

  void add(String name, Future<void> Function() handler, {Map<String, dynamic>? data}) {
    _pending.add(_Job(name, handler, data));
    _pump();
  }

  void _pump() {
    while (_active < concurrency && _pending.isNotEmpty) {
      final job = _pending.removeAt(0);
      _active++;
      job.handler().whenComplete(() {
        _active--;
        _pump();
      });
    }
  }

  Future<void> processAll() async {
    _running = true;
    while (_pending.isNotEmpty || _active > 0) {
      _pump();
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    _running = false;
  }

  int get pending => _pending.length;
  bool get isRunning => _running;
}

class _Job {
  _Job(this.name, this.handler, this.data);
  final String name;
  final Future<void> Function() handler;
  final Map<String, dynamic>? data;
}
