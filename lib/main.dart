import 'package:flutter/material.dart';
import 'package:pfpcl/settings/connection_settings.dart';

import 'package:pfpcl/tcp/message_connection.dart';
import 'package:pfpcl/tcp/pfp_client.dart';
import 'package:pfpcl/screens/messages_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final MessageConnection connection = TcpClient();
  final settings = await ConnectionSettings.load();
  runApp(PFPClient(connection: connection, settings: settings));
}

class PFPClient extends StatelessWidget {
  final MessageConnection connection;
  final ConnectionSettings settings;

  const PFPClient({super.key, required this.connection, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter TCP Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),

      home: MessagesPage(
        title: 'Flutter Demo Home Page', 
        connection: connection,
        settings: settings
      ),
    );
  }
}
