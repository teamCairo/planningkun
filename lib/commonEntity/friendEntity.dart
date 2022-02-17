import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:planningkun/commonEntity/userData.dart';

import 'commonEntity.dart';


final friendDataProvider = ChangeNotifierProvider(
      (ref) => FriendDataNotifier(),
);

class FriendDataNotifier extends ChangeNotifier {
  Map<String, Map<String, String>> _friendData = {};//キーはFriendのuserDocId
  Map<String, Map<String, String>> get friendData => _friendData;

  Map<String, Image?> _friendPhotoData = {};//キーはFriendのuserDocId
  get friendPhotoData => _friendPhotoData;

  Future<void> readFriendPhotoFromFirebaseToDirectoryAndMemory(WidgetRef ref,String friendUserDocId) async {

    String photoPath = _friendData[friendUserDocId]!["profilePhotoPath"]!;
    String photoFileName=photoPath.substring(photoPath.lastIndexOf('/')+1,);

    if(photoPath.contains("mainPhoto")){
      //写真が登録されている場合

      FirebaseStorage storage =  FirebaseStorage.instance;
      try {
        Reference imageRef =  storage.ref().child("profile").child(friendUserDocId).child(photoFileName);
        String imageUrl = await imageRef.getDownloadURL();
        _friendPhotoData[friendUserDocId] = Image.network(imageUrl,width:90);

        Directory appDocDir = await getApplicationDocumentsDirectory();
        File downloadToFile = File("${appDocDir.path}/friend/"+photoFileName);

        await imageRef.writeToFile(downloadToFile);

      }catch(e){
        //写真があるはずなのになぜかエラーだった
        _friendPhotoData[friendUserDocId] =null;
      }

    }else{
      //写真が登録されていない場合
      _friendPhotoData[friendUserDocId] =null;
    }
  }

  Future<void> readFriendPhotoDataFromDirectoryToMemory(WidgetRef ref,String friendUserDocId) async {

    String photoPath = _friendData[friendUserDocId]!["profilePhotoPath"]!;
    String photoFileName=photoPath.substring(photoPath.lastIndexOf('/')+1,);

    Directory appDocDir = await getApplicationDocumentsDirectory();
    File localFile = File("${appDocDir.path}/friend/"+photoFileName);

    _friendPhotoData[friendUserDocId] = Image.file(localFile,width:90);
  }


  Future<void> readFriendDataFromFirebaseToHiveAndMemory(WidgetRef ref,
      String userDocId) async {
    await FirebaseFirestore.instance
        .collection('friends')
        .where('userDocId', isEqualTo: userDocId)
        .get()
        .then((QuerySnapshot snapshot) async {
      var boxFriend = await Hive.openBox('friend');
      await boxFriend.clear();
      _friendData.clear();

      snapshot.docs.forEach((doc) async {
        //Hiveとメモリにデータをセットする処理を追加
        await boxFriend.put(doc.get('friendUserDocId'), {
          'friendDocId': doc.id,
          'friendUserName': doc.get('friendUserName'),
          'lastMessageContent': doc.get('lastMessageContent'),
          'lastMessageDocId': doc.get('lastMessageDocId'),
          'lastTime': doc.get('lastTime'),
          'profilePhotoUpdateCnt': doc.get('profilePhotoUpdateCnt'),
          'profilePhotoPath': doc.get('profilePhotoPath'),
        });

        _friendData[doc.get('friendUserDocId')] = {
          'friendDocId': doc.id,
          'friendUserName': doc.get('friendUserName'),
          'lastMessageContent': doc.get('lastMessageContent'),
          'lastMessageDocId': doc.get('lastMessageDocId'),
          'lastTime': doc.get('lastTime'),
          'profilePhotoUpdateCnt': doc.get('profilePhotoUpdateCnt'),
          'profilePhotoPath': doc.get('profilePhotoPath'),
        };

        readFriendPhotoFromFirebaseToDirectoryAndMemory(ref,doc.get('friendUserDocId'));
      });
      await boxFriend.close();
    });
    notifyListeners();
  }

  Future<void> insertFriend(WidgetRef ref,String friendUserDocId) async{

    String insertedDocId="";
    DocumentSnapshot<Map<String, dynamic>>firebaseUserData = await FirebaseFirestore.instance
        .collection('users')
        .doc(friendUserDocId)
        .get();

    //相手側のFriendデータもFirebaseのみに作成する
    FirebaseFirestore.instance.collection('friends').add(
      {'userDocId':friendUserDocId,
        'friendUserDocId': ref.watch(userDataProvider).userData["userDocId"],
        'friendUserName': ref.watch(userDataProvider).userData["name"],
        'profilePhotoPath':ref.watch(userDataProvider).userData["profilePhotoPath"] ,
        'profilePhotoUpdateCnt': ref.watch(userDataProvider).userData["profilePhotoUpdateCnt"] ,
        'lastMessageContent': "",
        'lastMessageDocId': "",
        'lastTime': DateTime.now().toString(),
        'insertUserDocId':ref.watch(userDataProvider).userData["userDocId"],
        'insertProgramId': "friendProfile",
        'insertTime': DateTime.now().toString(),
      },
    );

    FirebaseFirestore.instance.collection('friends').add(
      {'userDocId':ref.watch(userDataProvider).userData["userDocId"] ,
        'friendUserDocId': friendUserDocId,
        'friendUserName': firebaseUserData["name"] ,
        'profilePhotoPath': firebaseUserData["profilePhotoPath"] ,
        'profilePhotoUpdateCnt': firebaseUserData["profilePhotoUpdateCnt"] ,
        'lastMessageContent': "",
        'lastMessageDocId': "",
        'lastTime': DateTime.now().toString(),
        'insertUserDocId':ref.watch(userDataProvider).userData["userDocId"],
        'insertProgramId': "friendProfile",
        'insertTime': DateTime.now().toString(),
      },
    ).then((value){
      insertedDocId=value.id;
    });

    var friendBox = await Hive.openBox('friend');
    await friendBox.put(friendUserDocId,{
      'friendUserDocId': insertedDocId,
      'friendUserName': firebaseUserData["name"],
      'profilePhotoPath': firebaseUserData["profilePhotoPath"] ,
      'profilePhotoUpdateCnt': firebaseUserData["profilePhotoUpdateCnt"] ,
      'lastMessageContent': "",
      'lastMessageDocId': "",
      'lastTime': DateTime.now().toString(),
    });
    await friendBox.close();

    ref.watch(friendDataProvider).friendData[friendUserDocId]={
      'friendUserDocId': insertedDocId,
      'friendUserName': firebaseUserData["name"],
      'profilePhotoPath': firebaseUserData["profilePhotoPath"] ,
      'profilePhotoUpdateCnt': firebaseUserData["profilePhotoUpdateCnt"],
      'lastMessageContent': "",
      'lastMessageDocId': "",
      'lastTime': DateTime.now().toString(),
    };


    await readFriendPhotoFromFirebaseToDirectoryAndMemory(ref,friendUserDocId);

  }

}