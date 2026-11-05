import 'dart:convert';

class PartyPacket {
  final String name;
  final String job;
  final int level;

  const PartyPacket({
    required this.name, 
    required this.job, 
    required this.level
  });

  factory PartyPacket.fromJson(Map<String, dynamic> json) => PartyPacket(
    name: json['name'] as String,
    job: json['job'] as String, 
    level: (json['level'] as num).toInt()
  );
  
  static List<PartyPacket>? tryParseMembers(String message) {
    try {
      final decoded = jsonDecode(message);
      if(decoded is! Map<String, dynamic>) return null;

      final members = decoded['members'];
      if(members is! List) return null;

      return members
        .map((element) => PartyPacket.fromJson(element as Map<String, dynamic>))
        .toList(growable: false);
    } catch (exception) {
      rethrow;
      //return null;
    }
  }
}