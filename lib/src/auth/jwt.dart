import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../errors.dart';

/// HMAC-SHA256 JWT implementation — no external JWT package needed.
class JwtService {
  JwtService({required this.secret, this.expiry = const Duration(hours: 24)});

  final String secret;
  final Duration expiry;

  String sign(Map<String, dynamic> payload) {
    final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
    final claims = Map<String, dynamic>.from(payload);
    claims['exp'] = DateTime.now().add(expiry).millisecondsSinceEpoch ~/ 1000;
    final body = base64Url.encode(utf8.encode(jsonEncode(claims)));
    final sig = _sign('$header.$body');
    return '$header.$body.$sig';
  }

  Map<String, dynamic> verify(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw UnauthorizedException('Invalid JWT');

    final expected = _sign('${parts[0]}.${parts[1]}');
    if (!_safeEquals(expected, parts[2])) {
      throw UnauthorizedException('Invalid JWT signature');
    }

    final payload = jsonDecode(utf8.decode(base64Url.decode(_pad(parts[1]))))
        as Map<String, dynamic>;

    final exp = payload['exp'] as int?;
    if (exp != null && DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp) {
      throw UnauthorizedException('JWT expired');
    }
    return payload;
  }

  String _sign(String input) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    return base64Url.encode(hmac.convert(utf8.encode(input)).bytes);
  }

  String _pad(String input) {
    final mod = input.length % 4;
    if (mod == 0) return input;
    return input + '=' * (4 - mod);
  }

  bool _safeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

/// In-memory session store.
class SessionStore {
  final Map<String, Session> _sessions = {};

  Session create({required String userId, Map<String, dynamic> data = const {}}) {
    final id = _generateId();
    final session = Session(id: id, userId: userId, data: data);
    _sessions[id] = session;
    return session;
  }

  Session? get(String id) => _sessions[id];

  void destroy(String id) => _sessions.remove(id);

  String _generateId() {
    final rand = Random.secure();
    return List.generate(32, (_) => rand.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}

class Session {
  Session({required this.id, required this.userId, this.data = const {}});
  final String id;
  final String userId;
  final Map<String, dynamic> data;
}
