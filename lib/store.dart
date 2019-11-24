import 'dart:async';
import 'package:flutter/foundation.dart';
import './utils.dart';

class Store {
  Backend backend;

  Store(this.backend);

  Future<Status> markTodoAsDone(todoText) async {
    return backend
        .updateFile((orgText) => Org().markTodoAsDone(todoText, orgText));
  }

  Future<Status> addTodo(todoText) async {
    return backend.updateFile((orgText) => Org().addTodo(todoText, orgText));
  }

  Future<List<Todo>> fetchTodos() async {
    return backend.loadFileContent().then((contentStatus) {
      debugPrint('contentStatus: $contentStatus');
      if (!contentStatus.isOK()) {
        return List();
      }
      var orgText = contentStatus.msg;
      return Org()
          .parseTodos(orgText)
          .reversed
          .where((todo) => todo.todoState == TodoState.TODO)
          .toList();
    }, onError: (e) {
      return [new Todo(e.toString(), 0, TodoState.OTHER)];
    });
  }
}
