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
}