import 'package:shared_preferences/shared_preferences.dart';

class ConnectionSettings {
  static const _hostKey = 'host';
  static const _portKey = 'port';

  static const _defaultHost = '192.168.1.67';
  static const _defaultPort = 8089;

  String host;
  int port;

  ConnectionSettings({this.host = _defaultHost, this.port = _defaultPort});

  static Future<ConnectionSettings> load() async {
    final preferences = await SharedPreferences.getInstance();

    return ConnectionSettings(
      host: preferences.getString(_hostKey) ?? _defaultHost,
      port: preferences.getInt(_portKey) ?? _defaultPort,
    );
  }

  Future<void> save() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_hostKey, host);
    await preferences.setInt(_portKey, port);
  }
}