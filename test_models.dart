import 'dart:convert';
import 'dart:io';

void main() async {
  final apiKey = 'YOUR_API_KEY';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=' + apiKey);
  
  try {
    final request = await HttpClient().getUrl(url);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    print('Response status: ' + response.statusCode.toString());
    print('Response body: ' + responseBody);
  } catch (e) {
    print('Error: ' + e.toString());
  }
}
