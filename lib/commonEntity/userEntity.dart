import 'dart:async';
import 'dart:core';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class UserDataProviderNotifier extends ChangeNotifier {
  Map<String, dynamic> _userData = {};
  get userData => _userData;
  Image? _mainPhotoData;
  get mainPhotoData => _mainPhotoData;

  List<String> itemNameList = [
    "name",
    "email",
    "age",
    "ageNumber",
    "level",
    "occupation",
    "nativeLang",
    "country",
    "town",
    "homeCountry",
    "homeTown",
    "gender",
    "placeWannaGo",
    "greeting",
    "description",
    "searchConditionAge",
    "searchConditionLevel",
    "searchConditionNativeLang",
    "searchConditionCountry",
    "searchConditionGender",
    "profilePhotoNameSuffix",
    "profilePhotoUpdateCnt",
    "lastLoginTime",
    "insertUserDocId",
    "insertProgramId",
    "insertTime",
    "updateUserDocId",
    "updateProgramId",
    "updateTime",
    "readableFlg",
    "deleteFlg"
  ];

  Stream<QuerySnapshot>? _callStream;
  final controller = StreamController<bool>();
  StreamSubscription<QuerySnapshot>? streamSub;


  Future<void> updatelastLoginTime() async {
    FirebaseFirestore.instance.collection('users').doc(_userData["userDocId"]).update({'lastLoginTime': FieldValue.serverTimestamp()});
  }


  Future<void> readMainPhotoDataFromDirectoryToMemory() async {
    if ((_userData["profilePhotoNameSuffix"] == null?"":_userData["profilePhotoNameSuffix"]) == "") {
      _mainPhotoData = null;
    } else {
      String profilePhotoNameSuffix = _userData["profilePhotoNameSuffix"]!;
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile =
          File("${appDocDir.path}/media/mainPhoto" + profilePhotoNameSuffix);
      _mainPhotoData = Image.file(localFile, width: 90);
    }
  }

  Future<void> readMainPhotoFromFirebaseToDirectoryAndMemory(String profilePhotoNameSuffix) async {
    if (profilePhotoNameSuffix == "") {
      _mainPhotoData = null;
    } else {

      FirebaseStorage storage = FirebaseStorage.instance;
      Reference imageRef = storage
          .ref()
          .child("profile")
          .child(_userData["userDocId"]!)
          .child("mainPhoto" + profilePhotoNameSuffix);
      String imageUrl = await imageRef.getDownloadURL();

      _mainPhotoData = Image.network(imageUrl, width: 90);

      Directory appDocDir = await getApplicationDocumentsDirectory();
      File downloadToFile =
          File("${appDocDir.path}/media/mainPhoto" + profilePhotoNameSuffix);
      try {
        await imageRef.writeToFile(downloadToFile);
      } catch (e) {
        _mainPhotoData = null;
        log("????????????????????????????????????");
      }
    }
  }

  void closeStream() async {
    streamSub!.cancel();
    log("XXXXXX before controllerClose");
    // controller.close();
  }

  void setUnitItem(String itemName, String value) {
    _userData[itemName] = value;
    notifyListeners();
  }

  Future<void> readUserDataFromHiveToMemory() async {
    var boxUser = Hive.box('user');

    _userData["userDocId"] = boxUser.get("userDocId");

    for (int i = 0; i < itemNameList.length; i++) {
      _userData[itemNameList[i]] = boxUser.get(itemNameList[i]);
    }

    await readMainPhotoDataFromDirectoryToMemory();
    log("XXXXXX after read user");
  }

  void controlStreamOfReadUserDataFirebaseToHiveAndMemory(
      String userDocId) async {
    //???????????????????????????
    streamSub = await readUserDataFirebaseToHiveAndMemory(userDocId);

    if (controller.hasListener) {
    } else {
      //2???????????????????????????????????????????????????????????????
      controller.stream.listen((value) async {
        log("XXXXXXXXXXXXXCANCEL??????");
        streamSub!.cancel();
        streamSub = await readUserDataFirebaseToHiveAndMemory(userDocId);
      });
    }
  }

  Future<StreamSubscription<QuerySnapshot>> readUserDataFirebaseToHiveAndMemory(
      String email) async {
    var boxSetting = Hive.box('setting');
    var boxUser = Hive.box('user');
    DateTime userUpdatedTime = await boxSetting.get("userUpdateCheck");

    log("XXXXXXXXXXXXXXXXXXXXXXXX??????????????????" + userUpdatedTime.toString());
    _callStream = FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .where('updateTime', isGreaterThan: Timestamp.fromDate(userUpdatedTime))
        .where('readableFlg', isEqualTo: true)
        .snapshots();

    StreamSubscription<QuerySnapshot> streamSub =
        _callStream!.listen((QuerySnapshot snapshot) async {
      log("XXXXXXXXXXXXXXXXXXXXXXXXListen???????????????Size" + snapshot.size.toString());
      if (snapshot.size != 0) {
        if(_userData["profilePhotoUpdateCnt"]!=null){
          if (_userData["profilePhotoUpdateCnt"]<
              snapshot.docs[0].get("profilePhotoUpdateCnt")) {
            //??????????????????????????????????????????????????????????????????DL
            await readMainPhotoFromFirebaseToDirectoryAndMemory(snapshot.docs[0].get("profilePhotoNameSuffix")==null?"":snapshot.docs[0].get("profilePhotoNameSuffix"));
          }
        }
        await boxUser.put("userDocId", snapshot.docs[0].id);
        _userData["userDocId"] = snapshot.docs[0].id;

        boxSetting.put("email",snapshot.docs[0].get("email"));
        boxSetting.put("userDocId",snapshot.docs[0].id);

        for (int i = 0; i < itemNameList.length; i++) {
          if (itemNameList[i] == "updateTime" ||
              itemNameList[i] == "insertTime" ||
              itemNameList[i] == "lastLoginTime") {
            _userData[itemNameList[i]] =
                snapshot.docs[0].get(itemNameList[i]).toDate();
            await boxUser.put(itemNameList[i],
                snapshot.docs[0].get(itemNameList[i]).toDate());
          } else {
            _userData[itemNameList[i]] = snapshot.docs[0].get(itemNameList[i]);
            await boxUser.put(
                itemNameList[i], snapshot.docs[0].get(itemNameList[i]));
          }
        }

        log("XXXXXXXXXXXXXXXXXXXXXXXX?????????????????????ID" + snapshot.docs[0].id);
        log("XXXXXXXXXXXXXXXXXXXXXXXX??????????????????SnapshotDocsDate" +
            snapshot.docs[0].get("updateTime").toDate().toString());
        await boxSetting.put(
            "userUpdateCheck", snapshot.docs[0].get("updateTime").toDate());

        log("XXXXXXXXXXXXXADD??????USER???");
        controller.sink.add(true);
        log("XXXXXXXXXXXXXADD??????USER???");
        notifyListeners();
      }
    });

    return streamSub;
  }

  Future<void> uploadAndInsertPhoto(File imageFile, WidgetRef ref) async {
    _mainPhotoData = Image.file(imageFile);

    String pathStr = imageFile.path;
    String pathStrEx = pathStr.substring(
      pathStr.lastIndexOf('.'),
    );
    FirebaseStorage storage = FirebaseStorage.instance;
    try {
      await storage
          .ref("profile/" + _userData["userDocId"]! + "/mainPhoto" + pathStrEx)
          .putFile(imageFile);

      //?????????????????????
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File downloadToFile =
          File("${appDocDir.path}/media/" + "mainPhoto" + pathStrEx);
      await downloadToFile.writeAsBytes(await imageFile.readAsBytes());

      var box = Hive.box('user');
      _userData["profilePhotoUpdateCnt"] =
          _userData["profilePhotoUpdateCnt"]! + 1;
      _userData["profilePhotoNameSuffix"] = pathStrEx;
      await box.put(
          "profilePhotoUpdateCnt", _userData["profilePhotoUpdateCnt"]! + 1);
      await box.put("profilePhotoNameSuffix", pathStrEx);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userData["userDocId"]!)
          .update({
        "profilePhotoUpdateCnt": _userData["profilePhotoUpdateCnt"]! + 1,
        "profilePhotoNameSuffix": pathStrEx
      });

      var result = await FlutterImageCompress.compressAndGetFile(
        "${appDocDir.path}/media/" + "mainPhoto" + pathStrEx,
        "${appDocDir.path}/media/" + "mainPhoto_small" + pathStrEx,
        quality: 20,
      );

      File localSmallFile =
          File("${appDocDir.path}/media/" + "mainPhoto_small" + pathStrEx);
      await storage
          .ref("profile/" +
              _userData["userDocId"]! +
              "/mainPhoto_small" +
              pathStrEx)
          .putFile(localSmallFile);
    } catch (e) {
      print(e);
    }

    notifyListeners();
  }

  Future<void> setImage(WidgetRef ref) async {
    XFile? pickerFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 40);
    if (pickerFile != null) {
      uploadAndInsertPhoto(File(pickerFile.path), ref);
      //TODO ????????????????????????
    }
  }


  void clearHiveAndMemoryAndDirectory()async {

    _userData = {};
    _mainPhotoData=null;

    var boxSetting = Hive.box('setting');
    await boxSetting.put("userUpdateCheck",DateTime(2022, 1, 1, 0, 0));
    boxSetting.delete("email");
    boxSetting.delete("userDocId");
    var boxUser = Hive.box('user');
    await boxUser.deleteFromDisk();
    await Hive.openBox('user');
    final userDir = Directory((await getApplicationDocumentsDirectory()).path+"/media");

    List<FileSystemEntity> files;
    files = userDir.listSync(recursive: true,followLinks: false);
    for (var file in files) {
      file.deleteSync(recursive: true);
    }

    log("XXXXXXXXfinishDelete");
  }
}

final userDataProvider = ChangeNotifierProvider(
  (ref) => UserDataProviderNotifier(),
);
