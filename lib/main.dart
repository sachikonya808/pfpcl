import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:pfpcl/service/service_connection.dart';
import 'package:pfpcl/settings/connection_settings.dart';
import 'package:pfpcl/tcp/message_connection.dart';
import 'package:pfpcl/screens/party_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  ServiceConnection.initService();

  final MessageConnection connection = ServiceConnection();
  final settings = await ConnectionSettings.load();
  runApp(PFPClient(connection: connection, settings: settings));
}

class PFPClient extends StatelessWidget {
  final MessageConnection connection;
  final ConnectionSettings settings;

  const PFPClient({super.key, required this.connection, required this.settings});

  //Fallback
  static final _fallbackSeed = Colors.indigo.shade900;
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightScheme = lightDynamic ??
          ColorScheme.fromSeed(seedColor: _fallbackSeed);
        final darkScheme = darkDynamic ??
          ColorScheme.fromSeed(
            seedColor: _fallbackSeed,
            brightness: Brightness.dark
          );

        return MaterialApp(
          title: 'PF Phone Link - Client',
          theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
          darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
          themeMode: ThemeMode.system,

          home: MessagesPage(
            title: 'PFPL: Party Members', 
            connection: connection,
            settings: settings
          ),
        );
      },
    );
  }
}
