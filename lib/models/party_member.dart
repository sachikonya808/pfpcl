class PartyMember {
  final String name;
  final String job;
  final int level;
  //Future fields go here

  const PartyMember({
    required this.name, 
    required this.job, 
    required this.level
    //And here
  });

  factory PartyMember.fromJson(Map<String, dynamic> json) => PartyMember(
    name: json['name'] as String,
    job: json['job'] as String, 
    level: (json['level'] as num).toInt()
    //...And here
  );
}