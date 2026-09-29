import 'dart:convert';
import 'dart:html' as html;

Future<List<Map<String, dynamic>>> fetchUsers() async {
  try {
    final request = await html.HttpRequest.request(
      'http://127.0.0.1:2626/usuarios',
      method: 'GET',
      requestHeaders: const {'Accept': 'application/json'},
    );
    final status = request.status ?? 0;
    if (status < 200 || status >= 300) {
      throw Exception('El servidor respondió con código $status.');
    }
    final decoded = jsonDecode(request.responseText ?? '');
    if (decoded is! List) throw const FormatException('Formato de respuesta inesperado.');
    return decoded.whereType<Map<String, dynamic>>().toList();
  } catch (e) {
    if (e is FormatException || e is Exception) rethrow;
    throw Exception('No se pudo conectar. Revisa que la API permita solicitudes CORS desde Chrome.');
  }
}
