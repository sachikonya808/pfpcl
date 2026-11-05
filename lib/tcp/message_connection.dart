import 'package:pfpcl/models/party_packet.dart';

enum ConnectionStatus { disconnected, connecting, connected }

abstract class MessageConnection {
  Stream<String> get messages;
  Stream<ConnectionStatus> get status;
  ConnectionStatus get currentStatus;

  Stream<List<PartyPacket>> get packets;
  List<PartyPacket>? get latestPackets;

  List<String> get history;

  Future<void> connect(String host, int port);
  Future<void> disconnect();

  void dispose();
}