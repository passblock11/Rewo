import 'dart:async';

import 'package:postgres/postgres.dart';

/// Lightweight Postgres connection pool — no ORM overhead.
class PostgresPool {
  PostgresPool({
    required this.endpoint,
    this.maxConnections = 10,
    this.sslMode = SslMode.disable,
  });

  factory PostgresPool.fromUrl(String url, {int maxConnections = 10}) {
    final uri = Uri.parse(url);
    final db = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.first.replaceFirst('/', '')
        : 'postgres';
    return PostgresPool(
      endpoint: Endpoint(
        host: uri.host,
        port: uri.port == 0 ? 5432 : uri.port,
        database: db,
        username: uri.userInfo.split(':').first,
        password: uri.userInfo.contains(':')
            ? uri.userInfo.split(':').skip(1).join(':')
            : null,
      ),
      maxConnections: maxConnections,
      sslMode: uri.scheme.contains('ssl') ? SslMode.require : SslMode.disable,
    );
  }

  final Endpoint endpoint;
  final int maxConnections;
  final SslMode sslMode;

  final List<Connection> _idle = [];
  final List<Connection> _busy = [];
  final List<_PendingQuery> _waitQueue = [];
  bool _closed = false;

  Future<void> open() async {
    for (var i = 0; i < maxConnections; i++) {
      _idle.add(await _connect());
    }
  }

  Future<Connection> _connect() {
    return Connection.open(endpoint, settings: ConnectionSettings(sslMode: sslMode));
  }

  Future<List<Map<String, dynamic>>> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    return _withConnection((conn) async {
      final result = await conn.execute(
        parameters == null ? Sql(sql) : Sql.named(sql),
        parameters: parameters ?? {},
      );
      return result.map((row) => row.toColumnMap()).toList();
    });
  }

  Future<int> execute(String sql, {Map<String, dynamic>? parameters}) async {
    return _withConnection((conn) async {
      final result = await conn.execute(
        parameters == null ? Sql(sql) : Sql.named(sql),
        parameters: parameters ?? {},
      );
      return result.affectedRows;
    });
  }

  Future<T> transaction<T>(Future<T> Function(Connection conn) action) async {
    return _withConnection((conn) async {
      await conn.execute('BEGIN');
      try {
        final result = await action(conn);
        await conn.execute('COMMIT');
        return result;
      } catch (e) {
        await conn.execute('ROLLBACK');
        rethrow;
      }
    });
  }

  Future<T> _withConnection<T>(Future<T> Function(Connection conn) action) async {
    if (_closed) throw StateError('Pool is closed');
    if (_idle.isEmpty && _busy.length < maxConnections) {
      _idle.add(await _connect());
    }
    if (_idle.isEmpty) {
      final completer = Completer<T>();
      _waitQueue.add(_PendingQuery(action, completer));
      return completer.future;
    }

    final conn = _idle.removeLast();
    _busy.add(conn);
    try {
      return await action(conn);
    } finally {
      _busy.remove(conn);
      _idle.add(conn);
      if (_waitQueue.isNotEmpty) {
        final pending = _waitQueue.removeAt(0);
        _withConnection(pending.action)
            .then(pending.completer.complete)
            .catchError(pending.completer.completeError);
      }
    }
  }

  Future<void> close() async {
    _closed = true;
    await Future.wait([..._idle, ..._busy].map((c) => c.close()));
    _idle.clear();
    _busy.clear();
  }
}

class _PendingQuery {
  _PendingQuery(this.action, this.completer);
  final Future<dynamic> Function(Connection conn) action;
  final Completer completer;
}
