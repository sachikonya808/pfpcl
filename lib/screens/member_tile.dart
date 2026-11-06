import 'package:flutter/material.dart';

import 'package:pfpcl/models/party_member.dart';
import 'package:pfpcl/screens/job_icons.dart';

class MemberTile extends StatelessWidget {
  final PartyMember partyMember;
  
  const MemberTile({super.key, required this.partyMember});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: JobIcon(
        name: partyMember.name, 
        job: partyMember.job
      ),

      title: Text(partyMember.name),
      subtitle: Text('Job ${partyMember.job} | Level : ${partyMember.level}')
    )
  );
}