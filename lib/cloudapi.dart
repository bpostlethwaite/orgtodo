import 'dart:convert';
import 'package:http/http.dart' as http;
import './dropbox.dart';
import 'package:flutter/foundation.dart';


class Todo{
  final String text;

  Todo({
    this.text,
  }) ;

  factory Todo.fromJson(Map<String, dynamic> json){
    return new Todo(
      text: json['text'],
    );
  }
}


class CloudAPI {
  Future<List<Todo>> parseTodos(String content) async {
    String url = 'https://us-central1-ben-utils.cloudfunctions.net/org-todo-parser';
    Map<String, String> headers = {"Content-type": "application/json"};
    Map<String, String> payload = {"org": content};
    String json = jsonEncode(payload);
    // make POST request
    return http.post(url, headers: headers, body: json).then((resp) {
      int statusCode = resp.statusCode;
      if (statusCode != 200) {
        return List();
      }
      List<dynamic> parsedJson = jsonDecode(resp.body);
      List<Todo> todos = parsedJson.map((i) => Todo.fromJson(i)).toList();
      return todos.reversed.toList();
    });
  }
}

Future<List<Todo>> fetchTodos() async {
  return Dropbox().loadFileContent().then((contentStatus) {
    debugPrint('contentStatus: $contentStatus');
    if (!contentStatus.isOK()) {
      return List();
    }
    var orgContent = contentStatus.msg;
    var cloudAPI = CloudAPI();
    Future<List<Todo>> todos = cloudAPI.parseTodos(orgContent);
    return todos;
  },
  onError: (e) {
      return [new Todo(text: e.toString())];
  });
}