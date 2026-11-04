import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:convert';

import 'package:pfpcl/tcp/message_connection.dart';

class TcpClient implements MessageConnection {
  static const _maxHistory = 500;

  Socket? _socket;
  StreamSubscription<String>? _subscription;
  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;
  final List<String> _history = [];

  final _messages = StreamController<String>.broadcast();
  final _status = StreamController<ConnectionStatus>.broadcast();

  @override
  Stream<String> get messages => _messages.stream;

  @override
  Stream<ConnectionStatus> get status => _status.stream;

  @override
  ConnectionStatus get currentStatus => _currentStatus;

  @override
  List<String> get history => UnmodifiableListView(_history);

  void _setStatus(ConnectionStatus status) {
    _currentStatus = status;
    _status.add(status);
  }

  void _onMessage(String message) {
    _history.insert(0, message);
    
    if(_history.length > _maxHistory) _history.removeLast();
    
    _messages.add(message);
  }

  @override
  Future<void> connect(String host, int port) async {
    if(_currentStatus != ConnectionStatus.disconnected) return;

    _setStatus(ConnectionStatus.connecting);
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      socket.setOption(SocketOption.tcpNoDelay, true);
      _socket = socket;
      _setStatus(ConnectionStatus.connected);

      _subscription = socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .listen(
          _onMessage,
          onError: (_) => disconnect(),
          onDone: disconnect,
          cancelOnError: true,
        );
    } catch (exception) {
      _setStatus(ConnectionStatus.disconnected);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    _socket?.destroy();
    _socket = null;
    if(_currentStatus != ConnectionStatus.disconnected) {
      _setStatus(ConnectionStatus.disconnected);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _socket?.destroy();
    _messages.close();
    _status.close();
  }
}