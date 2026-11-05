import 'dart:async';
import 'dart:collection';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pfpcl/models/party_packet.dart';
import 'package:pfpcl/service/tcp_task_handler.dart';
import 'package:pfpcl/tcp/message_connection.dart';

class ServiceConnection implements MessageConnection{
  static const _maxHistory = 5;

  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;
  List<PartyPacket>? _latest;
  final List<String> _history = [];

  Map<String, dynamic>? _pendingConnect;
  Completer<void>? _connecting;

  final _messages = StreamController<String>.broadcast();
  final _packets = StreamController<List<PartyPacket>>.broadcast();
  final _status = StreamController<ConnectionStatus>.broadcast();

  ServiceConnection() {
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    _syncIfRunning();
  }

  static void initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tcp_connection', 
        channelName: 'Server Connection',
        channelDescription: 'Shown while the app stays connected to the server.',
        onlyAlertOnce: true
      ), 
      
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false
      ), 
      
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: true
      )
    );
  }

  Future<void> _syncIfRunning() async {
    if(await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask({'cmd': 'sync'});
    }
  }

  void _setStatus(ConnectionStatus status) {
    if(status != _currentStatus) {
      _currentStatus = status;
      _status.add(status);
    }

    if(status == ConnectionStatus.disconnected) _stopService();
  }

  Future<void> _stopService() async {
    if(await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  void _handleLine(String line) {
    _history.insert(0, line);
    if(_history.length > _maxHistory) _history.removeLast();
    _messages.add(line);

    final party = PartyPacket.tryParseMembers(line);
    if(party == null) return;

    _latest = party;
    _packets.add(party);
  }

  void _onTaskData(Object data) {
    if(data is! Map) return;

    switch (data['type']) {
      case 'ready':
        final cmd = _pendingConnect;
        _pendingConnect = null;
        if(cmd != null) FlutterForegroundTask.sendDataToTask(cmd);
      case 'status':
        final status = ConnectionStatus.values.byName(data['value'] as String);
        if(status == ConnectionStatus.disconnected && _connecting != null) return;
        _setStatus(status);
      case 'message':
        _handleLine(data['line'] as String);
      case 'connectResult':
        final conn = _connecting;
        if(conn == null || conn.isCompleted) return;
        if(data['ok'] == true) {
          conn.complete();
        } else {
          conn.completeError(data['error'] ?? 'Connection failed');
        }
    }
  }
  
  static Future<void> _requestPermissions() async {
    final permission = await FlutterForegroundTask.checkNotificationPermission();
    
    if(permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if(!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  @override
  Future<void> connect(String host, int port) async {
    if(_currentStatus != ConnectionStatus.disconnected) return;
    _setStatus(ConnectionStatus.connecting);

    final done = _connecting = Completer<void>();
    final cmd = {'cmd': 'connect', 'host': host, 'port': port};

    try {
      await _requestPermissions();

      if(await FlutterForegroundTask.isRunningService) {
        FlutterForegroundTask.sendDataToTask(cmd);
      } else {
        _pendingConnect = cmd;
        final result = await FlutterForegroundTask.startService(
          serviceId: 256,
          serviceTypes: [ForegroundServiceTypes.remoteMessaging],
          notificationTitle: 'Connecting...', 
          notificationText: '$host:$port',
          callback: startCallback
        );
        if(result is ServiceRequestFailure) throw result.error;
      }
      await done.future.timeout(const Duration(seconds: 15));
    } catch (_) {
      _pendingConnect = null;
      _connecting = null;
      _setStatus(ConnectionStatus.disconnected);
      rethrow;
    }
    _connecting = null;
  }

  @override
  ConnectionStatus get currentStatus => _currentStatus;

  @override
  Future<void> disconnect() async {
    if(await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask({'cmd': 'disconnect'});
    } else {
      _setStatus(ConnectionStatus.disconnected);
    }
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    
    _messages.close();
    _packets.close();
    _status.close();
  }

  @override
  List<String> get history => UnmodifiableListView(_history);

  @override
  List<PartyPacket>? get latestPackets => _latest;

  @override
  Stream<String> get messages => _messages.stream;

  @override
  Stream<List<PartyPacket>> get packets => _packets.stream;

  @override
  Stream<ConnectionStatus> get status => _status.stream;

}