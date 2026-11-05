import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:convert';

import 'package:pfpcl/models/party_packet.dart';
import 'package:pfpcl/tcp/message_connection.dart';

class TcpClient implements MessageConnection {
  static const _maxHistory = 50;

  Socket? _socket;
  StreamSubscription<String>? _subscription;
  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;
  final List<String> _history = [];
  List<PartyPacket>? _latest;

  final _packets = StreamController<List<PartyPacket>>.broadcast();
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

  @override
  List<PartyPacket>? get latestPackets => _latest;

  @override
  Stream<List<PartyPacket>> get packets => _packets.stream;

  void _setStatus(ConnectionStatus status) {
    _currentStatus = status;
    _status.add(status);
  }

  void _onMessage(String message) {
    _history.insert(0, message);
    if(_history.length > _maxHistory) _history.removeLast();
    _messages.add(message);

    final party = PartyPacket.tryParseMembers(message);
    if(party == null) return;

    _latest = party;
    _packets.add(party);
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
    _packets.close();
    _status.close();
  }
}