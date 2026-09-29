import 'dart:convert';
import 'dart:io';

Future<List<Map<String, dynamic>>> fetchUsers() async {
  final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.getUrl(Uri.parse('http://$host:2626/usuarios'));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('El servidor respondió con código ${response.statusCode}.');
    }
    final decoded = jsonDecode(body);
    if (decoded is! List) throw const FormatException('Formato de respuesta inesperado.');
    return decoded.whereType<Map<String, dynamic>>().toList();
  } on SocketException {
    throw Exception('Comprueba que la API esté activa en el puerto 2626.');
  } finally {
    client.close(force: true);
  }
}
