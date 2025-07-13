import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final supabaseStorageUrl = dotenv.env['SUPABASE_BUCKET'];

Future<String?> downloadAndSaveImage(String fileName) async {
  try {
    final response = await http.get(Uri.parse('$supabaseStorageUrl/$fileName'));
    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = p.join(dir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return filePath;
    }
    return null;
  } catch (e) {
    return null;
  }
}
