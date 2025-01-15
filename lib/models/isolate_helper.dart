import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'package:flutter/services.dart';

mixin IsolateHelperMixin {
  static const int _maxIsolates = 5;

  int _currentIsolates = 0;

  final Queue<Function> _taskQueue = Queue();

  Future<T> loadWithIsolate<T>(Future<T> Function() function) async {
    if (_currentIsolates < _maxIsolates) {
      _currentIsolates++;
      return _executeIsolate(function);
    }

    final completer = Completer<T>();
    _taskQueue.add(() async {
      final result = await _executeIsolate(function);
      completer.complete(result);
    });
    return completer.future;
  }

  Future<T> _executeIsolate<T>(Future<T> Function() function) async {
    final ReceivePort receivePort = ReceivePort();
    final RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;

    final isolate = await Isolate.spawn(
      _isolateEntry,
      _IsolateEntryPayload(
        function: function,
        sendPort: receivePort.sendPort,
        rootIsolateToken: rootIsolateToken,
      ),
    );

    return receivePort.first.then(
      (dynamic data) {
        _currentIsolates--;
        _runNextTask();
        if (data is T) {
          isolate.kill(priority: Isolate.immediate);
          return data;
        } else {
          isolate.kill(priority: Isolate.immediate);
          throw data;
        }
      },
    );
  }

  void _runNextTask() {
    if (_taskQueue.isEmpty) return;
    final nextTask = _taskQueue.removeFirst();
    nextTask();
  }
}

Future<void> _isolateEntry(_IsolateEntryPayload payload) async {
  final Function function = payload.function;

  try {
    BackgroundIsolateBinaryMessenger.ensureInitialized(
      payload.rootIsolateToken,
    );
  } on MissingPluginException catch (e) {
    print(e.toString());
    // Sentry.captureException(e);
    return Future.error(e.toString());
  }

  final result = await function();
  payload.sendPort.send(result);
}

class _IsolateEntryPayload {
  const _IsolateEntryPayload({
    required this.function,
    required this.sendPort,
    required this.rootIsolateToken,
  });

  final Future<dynamic> Function() function;
  final SendPort sendPort;
  final RootIsolateToken rootIsolateToken;
}
