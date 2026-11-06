import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pfpcl/screens/member_tile.dart';
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
  late final StreamSubscription<dynamic> _packetSubscription;
  late final StreamSubscription<ConnectionStatus> _statusSubscription;

  MessageConnection get _connection => widget.connection;
  ConnectionSettings get _settings => widget.settings;

  @override
  void initState() {
    super.initState();

    _packetSubscription = _connection.messages.listen((_) {
      if(mounted) setState(() {});
    });

    _statusSubscription = _connection.status.listen((_) {
      if(mounted) setState(() {});
    });
  }
  
  @override
  void dispose() {
    _packetSubscription.cancel();
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
    final party = _connection.latestPacket;

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
            tooltip: 'Connection Settings'
          )
        ],
      ),
      
      body: party == null
      ? Center(
        child: Text(
          status == ConnectionStatus.connected
            ? 'Connected. Waiting for updates...'
            : 'Not connected (IP: ${_settings.host} | Port: ${_settings.port})',
          textAlign: TextAlign.center
        ),
      )
      
      : Column(
        children: [
          Padding(
            padding: const EdgeInsetsGeometry.fromLTRB(16, 16, 16, 4),
            child: Text(
              party.duty,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center
            ),
          ),

          Expanded(
            child: party.partyMembers.isEmpty
              ? const Center(child: Text('No party members found (Are you in a CW Party?)'))
              : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                itemCount: party.partyMembers.length,
                itemBuilder: (context, index) => MemberTile(partyMember: party.partyMembers[index])
              )
          )
        ],
      ),
          
      floatingActionButton: FloatingActionButton.extended(
        onPressed: status == ConnectionStatus.connecting ? null : _toggle,
        icon: fabIcon,
        label: Text(fabLabel)
      )
    );
  }
}