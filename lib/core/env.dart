import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiKey {
    final key = dotenv.env['GE_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GE_API_KEY not set in .env file');
    }
    return key;
  }
}
