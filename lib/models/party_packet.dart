import 'dart:convert';

import 'package:pfpcl/models/party_member.dart';

class PartyPacket {
  final List<PartyMember> partyMembers;
  //Future fields go here
  final String duty;

  const PartyPacket({
    required this.partyMembers,
    //And here
    required this.duty
  });

  factory PartyPacket.fromJson(Map<String, dynamic> json) {
    final partyMembers = json['members'];
    if(partyMembers is! List) {
      throw const FormatException('"members" is missing or not a List!');
    }

    return PartyPacket(
      partyMembers: partyMembers
        .map((element) => PartyMember.fromJson(element as Map<String, dynamic>))
        .toList(growable: false),
        //...And here...
      duty: json['duty'] as String
    );
  }

  static PartyPacket? tryParse(String line) {
    try {
      final decoded = jsonDecode(line);
      if(decoded is! Map<String, dynamic>) return null;

      return PartyPacket.fromJson(decoded);
    } catch (exception) {
      return null;
    }
  }
}