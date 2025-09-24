import 'dart:convert';

void main() {
  // Test the exact response from backend
  String response = '{"token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxMiwidXNlcm5hbWUiOiJub3ZhbmRyeWEiLCJyb2xlIjoidXNlciIsImlzcyI6InRtcy1iYWNrZW5kIiwiZXhwIjoxNzU4Njg0MjcyLCJpYXQiOjE3NTg1OTc4NzJ9.M_k-aeR91FA7LPpnWmCzulyKoYOfh6qGysj2LDM_0c8","user":{"id":12,"username":"novandrya","email":"novan@gmail.com","full_name":"novan","role":"user","created_at":"2025-09-19T03:08:59.5827Z","updated_at":"2025-09-19T03:08:59.5827Z"}}';
  
  print('Testing JSON parsing...');
  print('Response length: ${response.length}');
  print('First 10 chars: ${response.substring(0, 10)}');
  print('Last 10 chars: ${response.substring(response.length - 10)}');
  
  try {
    final jsonData = jsonDecode(response);
    print('JSON parsed successfully!');
    print('Token exists: ${jsonData['token'] != null}');
    print('User exists: ${jsonData['user'] != null}');
    print('User ID: ${jsonData['user']['id']}');
  } catch (e) {
    print('JSON parsing failed: $e');
  }
}