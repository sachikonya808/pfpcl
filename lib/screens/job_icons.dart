import 'package:flutter/material.dart';

class JobIcon extends StatelessWidget {
  final String name;
  final String job;

  const JobIcon({
    super.key,
    required this.name,
    required this.job
  });

  static const _images = {
    'AST': 'assets/icons/Astrologian.png',
    'BRD': 'assets/icons/Bard.png',
    'BLM': 'assets/icons/BlackMage.png',
    'DNC': 'assets/icons/Dancer.png',
    'DRK': 'assets/icons/DarkKnight.png',
    'DRG': 'assets/icons/Dragoon.png',
    'GNB': 'assets/icons/Gunbreaker.png',
    'MCH': 'assets/icons/Machinist.png',
    'MNK': 'assets/icons/Monk.png',
    'NIN': 'assets/icons/Ninja.png',
    'PLD': 'assets/icons/Paladin.png',
    'PCT': 'assets/icons/Pictomancer.png',
    'RPR': 'assets/icons/Reaper.png',
    'RDM': 'assets/icons/RedMage.png',
    'SGE': 'assets/icons/Sage.png',
    'SAM': 'assets/icons/Samurai.png',
    'SCH': 'assets/icons/Scholar.png',
    'SMN': 'assets/icons/Summoner.png',
    'VPR': 'assets/icons/Viper.png',
    'WAR': 'assets/icons/Warrior.png',
    'WHM': 'assets/icons/WhiteMage.png',
  };

  @override
  Widget build(BuildContext context) {
    final path = _images[job.trim()];

    if(path == null) {
      return CircleAvatar(
        child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
      );
    }

    return CircleAvatar(backgroundImage: AssetImage(path));    
  }
}