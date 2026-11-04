import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pfpcl/screens/settings_page.dart';
import 'package:pfpcl/settings/connection_settings.dart';
import 'package:pfpcl/tcp/message_connection.dart';

class MessagesPage extends StatefulWidget {
  final MessageConnection connection;
  final ConnectionSettings settings;
  final String title;

  const MessagesPage({
    super.key, 
    required this.title, 
    required this.connection,
    required this. settings
  });

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late final StreamSubscription<String> _messageSubscription;
  late final StreamSubscription<ConnectionStatus> _statusSubscription;

  MessageConnection get _connection => widget.connection;
  ConnectionSettings get _settings => widget.settings;

  @override
  void initState() {
    super.initState();

    _messageSubscription = _connection.messages.listen((_) {
      if(mounted) setState(() {});
    });

    _statusSubscription = _connection.status.listen((_) {
      if(mounted) setState(() {});
    });
  }
  
  @override
  void dispose() {
    _messageSubscription.cancel();
    _statusSubscription.cancel();

    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggle() async {
    if(_connection.currentStatus == ConnectionStatus.connected) {
      await _connection.disconnect();
      return;
    }

    try {
      await _connection.connect(_settings.host, _settings.port);
    } catch(exception) {
      if(mounted) _snack('Could not connect: $exception');
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => SettingsPage(title: 'Flutter Demo Settings', settings: _settings))  
    );

    if(mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final status = _connection.currentStatus;
    final messages = _connection.history;

    final(fabIcon, fabLabel) = switch(status){
      ConnectionStatus.disconnected => (
        const Icon(Icons.power_settings_new),
        'Connect'
      ),
      
      ConnectionStatus.connecting => (
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        'Connecting...'
      ),
      
      ConnectionStatus.connected => (
        const Icon(Icons.link_off),
        'Disconnect'
      )
    };
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _openSettings, 
            icon: const Icon(Icons.settings),
            tooltip: 'Connection Settings',
          )
        ],
      ),
      
      body: messages.isEmpty
      ? Center(
        child: Text(
          status == ConnectionStatus.connected
            ? 'Connected. Waiting for messages...'
            : 'Not connected (IP: ${_settings.host} | Port: ${_settings.port})',
          textAlign: TextAlign.center,
        ),
      )
      
      
      : ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) => ListTile(title: Text(messages[index]),),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: status == ConnectionStatus.connecting ? null : _toggle,
        icon: fabIcon,
        label: Text(fabLabel),
      )
    );
  }
}