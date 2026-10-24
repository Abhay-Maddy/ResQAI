import 'dart:io';

const Map<String, String> mimeTypes = {
  '.html': 'text/html; charset=UTF-8',
  '.js': 'application/javascript; charset=UTF-8',
  '.mjs': 'application/javascript; charset=UTF-8',
  '.wasm': 'application/wasm',
  '.json': 'application/json; charset=UTF-8',
  '.css': 'text/css; charset=UTF-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.webp': 'image/webp',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

Future<HttpServer> bindServer(List<int> candidatePorts) async {
  for (final port in candidatePorts) {
    try {
      final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      return server;
    } catch (_) {
      // Try next port
    }
  }
  // Fallback to ephemeral port 0 (OS assigns an available port)
  return await HttpServer.bind(InternetAddress.anyIPv4, 0);
}

void main() async {
  final webDir = Directory('build/web');
  if (!await webDir.exists()) {
    stderr.writeln('Error: "build/web" directory not found.');
    stderr.writeln('Run "flutter build web --base-href /" first.');
    exit(1);
  }

  final candidatePorts = [8080, 8081, 8082, 3000, 5000, 8000];
  final server = await bindServer(candidatePorts);
  final actualPort = server.port;

  stdout.writeln('============================================================');
  stdout.writeln(' ResQAI Production Web Server Active');
  stdout.writeln(' Local Link:    http://localhost:$actualPort');
  stdout.writeln(' Network Link:  http://127.0.0.1:$actualPort');
  stdout.writeln(' Serving files from: ${webDir.absolute.path}');
  stdout.writeln('============================================================');

  await for (final request in server) {
    try {
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'GET, OPTIONS, HEAD');
      request.response.headers.add('Access-Control-Allow-Headers', '*');

      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        continue;
      }

      String path = request.uri.path;
      if (path == '/' || path.isEmpty) {
        path = '/index.html';
      }

      // Prevent directory traversal
      final safePath = path.replaceAll(RegExp(r'\.\.+'), '');
      File file = File('${webDir.path}$safePath');

      // SPA routing fallback: if file does not exist, serve index.html
      if (!await file.exists() || await FileSystemEntity.isDirectory(file.path)) {
        file = File('${webDir.path}/index.html');
      }

      final dotIndex = file.path.lastIndexOf('.');
      final ext = dotIndex != -1 ? file.path.substring(dotIndex).toLowerCase() : '';
      final mime = mimeTypes[ext] ?? 'application/octet-stream';

      request.response.headers.set(HttpHeaders.contentTypeHeader, mime);
      request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');

      if (request.method == 'HEAD') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        continue;
      }

      await request.response.addStream(file.openRead());
      await request.response.close();
    } catch (e) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Internal Error: $e');
        await request.response.close();
      } catch (_) {}
    }
  }
}
