import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pfpcl/models/party_packet.dart';
import 'package:pfpcl/service/full_party_notifier.dart';

import 'package:pfpcl/tcp/message_connection.dart';
import 'package:pfpcl/tcp/pfp_client.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TcpTaskHandler());
}

class TcpTaskHandler extends TaskHandler {
  final _client = TcpClient();
  StreamSubscription<ConnectionStatus>? _statusSubscription;
  StreamSubscription<String>? _messageSubscription;

  String? _lastLine;
  String _target = '';
  
  int? _memberCount;
  String? _userName;
  String? _userJob;

  static const _partySize = 8;
  final _alerts = FPNotifier();
  bool _isPartyFull = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _alerts.init();

    _statusSubscription = _client.status.listen(_onStatus);
    
    _messageSubscription = _client.messages.listen((line) {
      _lastLine = line;
      FlutterForegroundTask.sendDataToMain({'type': 'message', 'line': line});
      
      final party = PartyPacket.tryParseMembers(line);
      if(party != null) {
        _memberCount = party.length;
        _userName = party[0].name;
        _userJob = party[0].job;
        _refreshNotification();
        _checkIfPartyFull(party.length);
      }
    });
    
    FlutterForegroundTask.sendDataToMain({'type': 'ready'});
  }

  void _onStatus(ConnectionStatus status) {
    FlutterForegroundTask.sendDataToMain({'type': 'status', 'value': status.name});
    
    if(status == ConnectionStatus.disconnected) {
      _memberCount = null;
      _isPartyFull = false;
    }
    _refreshNotification();
  }

  void _refreshNotification() {
    final status = _client.currentStatus;
    FlutterForegroundTask.updateService(
      notificationTitle: switch (status) {
        ConnectionStatus.connected => 'Connected',
        ConnectionStatus.connecting => 'Connecting...',
        ConnectionStatus.disconnected => 'Disconnected'
      },
      notificationText: (status == ConnectionStatus.connected && _memberCount != null)
        ? '$_userName | $_userJob | $_memberCount/8'
        : _target
    );
  }

  Future<void> _connect(String host, int port) async {
    _target = '$host:$port';

    try {
      await _client.connect(host, port);
      FlutterForegroundTask.sendDataToMain({'type': 'connectResult', 'ok': true});
    } catch (exception) {
      FlutterForegroundTask.sendDataToMain({'type': 'connectResult', 'ok': false, 'error': exception.toString()});
    }
  }

  void _checkIfPartyFull(int count) {
    final above = count >= _partySize;

    if(above && !_isPartyFull) {
      _alerts.show(
        'The Party has filled!', 
        '$count/$_partySize'
      );
    }

    _isPartyFull = above;
  }

  @override
  void onReceiveData(Object data) {
    if(data is! Map) return;

    switch (data['cmd']) {
      case 'connect':
        _connect(data['host'] as String, data['port'] as int);
      case 'disconnect':
        _client.disconnect();
      case 'sync':
        FlutterForegroundTask.sendDataToMain({'type': 'status', 'value': _client.currentStatus.name});
        final line = _lastLine;
        if(line != null) {
          FlutterForegroundTask.sendDataToMain({'type': 'message', 'line': line});
        }
    }    
  }
  
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _statusSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _client.disconnect();
    _client.dispose();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
  }
}