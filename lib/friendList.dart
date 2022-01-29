import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'firebase_config.dart';
import 'tabs_page.dart';
import 'friendList.dart';
import 'chat.dart';

class FriendList extends StatelessWidget {
  final argumentEmail;
  final argumentUserDocId;

  FriendList({this.argumentEmail,this.argumentUserDocId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
      ),
      body: buildFriendList(argumentEmail),
    );
  }


  Future<void> _insertOrMoveTalks(String oppositeUserDocId,BuildContext context) async {
    // addによるドキュメントIDを指定しない追加
    // この場合は、ドキュメントIDはハッシュ値が払い出されます
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('talks')
        .where('oppositeUserDocId', isEqualTo: oppositeUserDocId)
        .where('userDocId', isEqualTo: argumentUserDocId)
        .get();

    if(snapshot.size==0){
      FirebaseFirestore.instance.collection('talks').add({
        'lastMessageContent': "あああ",
        'lastMessageDocId': "",
        'lastTime': Timestamp.fromDate(DateTime.now()),
        'oppositeUserDocId': oppositeUserDocId,
        'userDocId': argumentUserDocId
      });
    }
    Navigator.push(
      context,MaterialPageRoute(
        builder: (context) => Chat(
          argumentUserDocId: argumentUserDocId,
          argumentOppositeUserDocId: oppositeUserDocId
        ),
      ),
    );



  }


  Widget buildFriendList(String email) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('email', isNotEqualTo: email)
          //.orderBy('name', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: const CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }
        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            final data = document.data()! as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: CircleAvatar(),
                trailing: Text(data['age'].toString()),
                title: Text(data['email']),
                subtitle: Text(data['name']),
                onTap: () {
                  _insertOrMoveTalks(document.id,context);
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

