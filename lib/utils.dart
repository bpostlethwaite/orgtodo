import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

enum TodoState { TODO, DONE, OTHER }

class Todo {
  static RegExp matchTodo = new RegExp(
      r"^(\*+)\s+(TODO|DONE)\s+?(.*?)\s*(:(?:\w+:)+)?$");

  static Todo fromLine(String line) {
    var match = matchTodo.firstMatch(line);
    if (match == null) {
      return null;
    }
    var level = match.group(1).length;
    var state = match.group(2);
    TodoState todoState;
    if (state == "TODO") {
      todoState = TodoState.TODO;
    } else if (state == "DONE") {
      todoState = TodoState.DONE;
    } else {
      todoState = TodoState.OTHER;
    }
    var text = match.group(3);
    return Todo(text, level, todoState);
  }

  final TodoState todoState;
  final String text;
  final int level;

  Todo(this.text, this.level, this.todoState);
}

class Status {
  int statusCode;
  String msg;

  Status(this.statusCode, this.msg);

  bool isOK() => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> toJson() {
    return jsonDecode(msg);
  }

  String toString() {
    var lines = msg.split('\n');
    var truncatedMsg = '';
    if (lines.length >= 7) {
      truncatedMsg = lines.sublist(0, 3).join('n') +
          '\n' +
          lines.sublist(lines.length - 3, lines.length).join('\n');
    } else {
      truncatedMsg = msg;
    }

    return "code: $statusCode\nmsg: $truncatedMsg";
  }
}

class Backend {
  Future<Status> updateFile(String Function(String) transform) async {
    return Status(999, "not implemented");
  }

  Future<Status> loadFileContent() async {
    return Status(999, "not implemented");
  }
}

class Org {
  String markTodoAsDone(String todoText, String orgText) {
    LineSplitter ls = new LineSplitter();
    List<String> lines = ls.convert(orgText);
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains(todoText) && lines[i].contains("TODO")) {
        debugPrint("REPLACING LINES");
        debugPrint("****: " + todoText);
        lines[i] = lines[i].replaceFirst("TODO", "DONE");
        debugPrint(lines[i]);
        break;
      }
    }
    return lines.join('\n');
  }

  String addTodo(String todoText, String orgText) {
    LineSplitter ls = new LineSplitter();
    List<String> lines = ls.convert(orgText);
    var todoLine = '* TODO $todoText';
    var scheduleLine = 'SCHEDULED: <${formatDateAsOrg(getNextWeekday())}>';

    lines.add(todoLine);
    lines.add(scheduleLine);

    return lines.join('\n');
  }

  List<Todo> parseTodos(String orgText) {
    LineSplitter ls = new LineSplitter();
    List<String> lines = ls.convert(orgText);
    List<Todo> todos = [];

    lines.forEach((line) {
      Todo todo = Todo.fromLine(line);
      if (todo != null) {
        todos.add(todo);
      }
    });
    return todos;
  }
}

DateTime getNextWeekday() {
  var now = DateTime.now();
  var tomorrow = now.add(Duration(days: 1));
  if (tomorrow.weekday == DateTime.saturday) {
    return tomorrow.add(Duration(days: 2));
  } else if (tomorrow.weekday == DateTime.sunday) {
    return tomorrow.add(Duration(days: 1));
  }
  return tomorrow;
}

String formatDateAsOrg(DateTime datetime) {
  var formatter = new DateFormat('yyyy-MM-dd E');
  return formatter.format(datetime);
}
