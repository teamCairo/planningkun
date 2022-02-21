import 'dart:async';
import 'dart:core';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:planningkun/config/topicDatabase.dart';

final topicDataProvider = ChangeNotifierProvider(
  (ref) => TopicDataNotifier(),
);

class TopicDataNotifier extends ChangeNotifier {
  Stream<QuerySnapshot>? _callStream;
  final controller = StreamController<bool>();
  StreamSubscription<QuerySnapshot>? streamSub;

  Future<void> readTopicPhotoFromFirebaseToDirectory(
      String topicDocId,String photoNameSuffix) async {

    FirebaseStorage storage = FirebaseStorage.instance;
    try {
      Reference imageRef =
          storage.ref().child("topics").child(topicDocId + photoNameSuffix);
      //log("XXXXXX before getdownloadurl");
      String imageUrl = await imageRef.getDownloadURL();
      //log("XXXXXX before appdocdir");
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File downloadToFile =
          File("${appDocDir.path}/topics/" + topicDocId + photoNameSuffix);
      log(imageUrl.toString());
      await imageRef.writeToFile(downloadToFile);
    } catch (e) {
      log("写真があるはずなのになぜかエラーだった_トピック");
    }
  }
  void closeStream() async {
    streamSub!.cancel();
  }

  void clearIsarAndDirectory()async {


    var boxSetting = Hive.box('setting');
    await boxSetting.put("topicsUpdateCheck",DateTime(2022, 1, 1, 0, 0));
    var isarInstance = Isar.getInstance();
    await isarInstance?.writeTxn((isar) async {
      isar.topics.clear();
    });
    final topicsDir = Directory((await getApplicationDocumentsDirectory()).path+"/topics");

    List<FileSystemEntity> files;
    files = topicsDir.listSync(recursive: true,followLinks: false);
    for (var file in files) {
      file.deleteSync(recursive: true);
    }

  }

  void controlStreamOfReadTopicNewDataFromFirebaseToIsar()async {

    //最初は必ず呼び出し
    //log("XXXXXXXXXXXXX初回readTopicNewDataFromFirebaseToHiveAndMemorycallする");
    streamSub=await readTopicNewDataFromFirebaseToIsar();
    //log("XXXXXXXXXXXXX初回readTopicNewDataFromFirebaseToHiveAndMemorycallした");

    if(controller.hasListener){

    }else{
      //log("XXXXXXXXXXXXXControlListener開始");
      //2回目以降は新しいデータを更新するたびに起動
      controller.stream.listen((value)  async{
        streamSub!.cancel();
        //log("XXXXXXXXXXXXXreadTopicNewDataFromFirebaseToHiveAndMemorycallする");
        streamSub=await readTopicNewDataFromFirebaseToIsar();
        //log("XXXXXXXXXXXXXreadTopicNewDataFromFirebaseToHiveAndMemorycallした");
      });
    }

  }

  Future<StreamSubscription<QuerySnapshot>> readTopicNewDataFromFirebaseToIsar() async {
    var boxSetting = Hive.box('setting');
    DateTime topicUpdatedTime = await boxSetting.get("topicsUpdateCheck");

    ////log("XXXXXXXXXXXXXQueryする"+topicUpdatedTime.toString());
    _callStream = FirebaseFirestore.instance
        .collection('topics')
        .where('updateTime',
            isGreaterThan: Timestamp.fromDate(topicUpdatedTime))
        .where('readableFlg', isEqualTo: true)
        .orderBy('updateTime', descending: false)
        .snapshots();


    StreamSubscription<QuerySnapshot> streamSub=_callStream!.listen((QuerySnapshot snapshot) async {
      if (snapshot.size != 0) {
        for(int i=0;i<snapshot.size;i++){

          if(snapshot.docs[i].get("deleteFlg")){

            var isarInstance = Isar.getInstance();
            await isarInstance?.writeTxn((isar) async {

              int result = await isar.topics.filter()
                  .topicDocIdEqualTo(snapshot.docs[i].id)
                  .deleteAll();

              if(result>0){
                if(snapshot.docs[i].get("fileNameSuffix")!=""){
                  deleteTopicPhotoFromDirectory(snapshot.docs[i].id+snapshot.docs[i].get("fileNameSuffix"));
                }
              }
            });


          }else{

            var isarInstance = Isar.getInstance();
            await isarInstance?.writeTxn((isar) async {
              List<Topic> resultList = await isar.topics.filter()
                  .topicDocIdEqualTo(snapshot.docs[i].id)
                  .findAll();


              if(resultList.length==0){

                final newTopic = new Topic(
                    snapshot.docs[i].id,
                    snapshot.docs[i].get("topicName"),
                    snapshot.docs[i].get("categoryDocId"),
                    snapshot.docs[i].get("categoryName"),
                    snapshot.docs[i].get("photoNameSuffix"),
                    snapshot.docs[i].get("photoUpdateCnt"),
                    snapshot.docs[i].get("insertUserDocId"),
                    snapshot.docs[i].get("insertProgramId"),
                    snapshot.docs[i].get("insertTime").toDate(),
                    snapshot.docs[i].get("updateUserDocId"),
                    snapshot.docs[i].get("updateProgramId"),
                    snapshot.docs[i].get("updateTime").toDate(),
                    snapshot.docs[i].get("readableFlg"),
                    snapshot.docs[i].get("deleteFlg"));

                newTopic.id = await isar.topics.put(newTopic);// insert

              }else{
                resultList[0].topicDocId=snapshot.docs[i].id;
                resultList[0].topicName=snapshot.docs[i].get("topicName");
                resultList[0].categoryDocId=snapshot.docs[i].get("categoryDocId");
                resultList[0].categoryName=snapshot.docs[i].get("categoryName");
                resultList[0].photoNameSuffix=snapshot.docs[i].get("photoNameSuffix");
                resultList[0].photoUpdateCnt=snapshot.docs[i].get("photoUpdateCnt");
                resultList[0].insertUserDocId=snapshot.docs[i].get("insertUserDocId");
                resultList[0].insertProgramId=snapshot.docs[i].get("insertProgramId");
                resultList[0].insertTime=snapshot.docs[i].get("insertTime").toDate();
                resultList[0].updateUserDocId=snapshot.docs[i].get("updateUserDocId");
                resultList[0].updateProgramId=snapshot.docs[i].get("updateProgramId");
                resultList[0].updateTime=snapshot.docs[i].get("updateTime").toDate();
                resultList[0].readableFlg=snapshot.docs[i].get("readableFlg");
                resultList[0].deleteFlg=snapshot.docs[i].get("deleteFlg");

                await isar.topics.put(resultList[0]);
              }

            });

            await readTopicPhotoFromFirebaseToDirectory(snapshot.docs[i].id,snapshot.docs[i].get("photoNameSuffix"));
          }
          //log("XXXXXXXXXXXXXDateリセットする"+topicUpdatedTime.toString()+">>>>"+snapshot.docs[i].get("updateTime").toDate().toString());
          if (snapshot.docs[i].get("updateTime").toDate().isAfter(topicUpdatedTime)) {
            topicUpdatedTime = snapshot.docs[i].get("updateTime").toDate();
            await boxSetting.put("topicsUpdateCheck", topicUpdatedTime);
          }

        }
        notifyListeners();

        //log("XXXXXXXXXXXXXADDする");
        controller.sink.add(true);
        //log("XXXXXXXXXXXXXADDした");
      }

    });
    return streamSub;

  }

  void deleteTopicPhotoFromDirectory(String fileName)async{

    final topicsPhotoFile = File((await getApplicationDocumentsDirectory()).path+"/topics/"+fileName);
    topicsPhotoFile.deleteSync(recursive: true);
    //log("filedeletefinish"+fileName);

  }
}
