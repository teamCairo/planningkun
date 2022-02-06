import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:planningkun/routes/settingEditPage.dart';
import 'package:video_player/video_player.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../firebase_config.dart';
import '../NotUse_tabs_page.dart';
import '../common.dart';


class Setting extends StatefulWidget {
  Map<String, String>  argumentUserData;
  Map<String, String> argumentMasterData;
  Map<String, Map<String,String>> argumentFriendData;

  Setting({required this.argumentUserData, required this.argumentMasterData, required this.argumentFriendData});

  @override
  _Setting createState() => _Setting();
}

class _Setting extends State<Setting> {
  // File? imageFile;
  //
  // Future showImagePicker() async{
  //
  //   final picker = ImagePicker();
  //   final pickedFile=await picker.getImage(source:ImageSource.gallery);
  //   //cameraの設定も可
  //
  //   imageFile = File(pickedFile!.path);
  // }
  Image? _img;
  //Text? _text;

  bool initialProcessFlg=true;

  var box;
  var firebaseUserData;


  Future<void> _download(String userDocId) async {
    // ファイルのダウンロード
    // テキスト
    FirebaseStorage storage = await FirebaseStorage.instance;

    // 画像
    Reference imageRef = await storage.ref().child("profile").child(userDocId).child("mainPhoto.png");
    String imageUrl = await imageRef.getDownloadURL();

      _img = Image.network(imageUrl,
      width:90);

    Directory appDocDir = await getApplicationDocumentsDirectory();
    File downloadToFile = File("${appDocDir.path}/mainPhoto.png");
    try {
      await imageRef.writeToFile(downloadToFile);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _upload(String userDocId) async {
    // imagePickerで画像を選択する
    // upload
    PickedFile? pickerFile =
        await ImagePicker().getImage(source: ImageSource.gallery,imageQuality:20 );
    File file = File(pickerFile!.path);
    //TODO 圧縮率などは調整

    // Future<PickedFile> getImage({
    //   @required ImageSource source,
    //   double maxWidth,
    //   double maxHeight,
    //   int imageQuality,
    //   CameraDevice preferredCameraDevice = CameraDevice.rear,
    // }) {
    //   // 略
    // }

    FirebaseStorage storage = FirebaseStorage.instance;
    try {
      await storage.ref("profile/" + userDocId + "/mainPhoto.png").putFile(file);
      //TODO 拡張子はPNGとは限らない。

      await FirebaseFirestore.instance.collection('users').doc(widget.argumentUserData["userDocId"])
          .update({"profilePhotoUpdateCnt": (int.parse(widget.argumentUserData["profilePhotoUpdateCnt"]!)+1).toString(),
        "profilePhotoPath": "profile/" + userDocId + "/mainPhoto.png"
          });


      widget.argumentUserData["profilePhotoUpdateCnt"]=(int.parse(widget.argumentUserData["profilePhotoUpdateCnt"]!)+1).toString();
      await box.put("profilePhotoPath","profile/" + userDocId + "/mainPhoto.png");

    } catch (e) {
      print(e);
    }
  }

  Future<void> _showLocalPhoto()async{


    Directory appDocDir = await getApplicationDocumentsDirectory();
    File localFile = File("${appDocDir.path}/mainPhoto.png");
    _img = Image.file(localFile,width:90);
    setState(()  {
    });
  }


  Future<void> getFirebaseData() async {


    firebaseUserData =await FirebaseFirestore.instance.collection('users').doc(widget.argumentUserData["userDocId"]).get();
    box = await Hive.openBox('record');


    if(firebaseUserData.get("profilePhotoUpdateCnt")!=widget.argumentUserData["profilePhotoUpdateCnt"]){
      await _download(widget.argumentUserData["userDocId"]!);

    }
    //FirebaseのデータをHiveに取得

    await arrangeUserDataUnit("name");
    await arrangeUserDataUnit("email");
    await arrangeUserDataUnit("age");
    await arrangeUserDataUnit("level");
    await arrangeUserDataUnit("occupation");
    await arrangeUserDataUnit("nativeLang");
    await arrangeUserDataUnit("country");
    await arrangeUserDataUnit("town");
    await arrangeUserDataUnit("homeCountry");
    await arrangeUserDataUnit("homeTown");
    await arrangeUserDataUnit("gender");
    await arrangeUserDataUnit("placeWannaGo");
    await arrangeUserDataUnit("greeting");
    await arrangeUserDataUnit("description");
    await arrangeUserDataUnit("profilePhotoPath");
    await arrangeUserDataUnit("profilePhotoUpdateCnt");

    await box.close();//Closeするとエラーになるのでオープンしたまま

    setState(()  {
    });
  }

  Future<void> arrangeUserDataUnit(String item) async {
    await box.put(item,firebaseUserData.get(item));
    widget.argumentUserData[item]=await firebaseUserData.get(item);
  }


  @override
  Widget build(BuildContext context) {

    if (initialProcessFlg){
      initialProcessFlg=false;
      _showLocalPhoto();
      //getFirebaseData();
    }


    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white10,
          elevation: 0.0,
          title: Text("Settings",
        style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 21,
        color: Colors.black87,
          ), // <- (※2)
        ),),
        body: SingleChildScrollView(
          child: SafeArea(
              child: Column(children: <Widget>[
                Center(
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.white,
                    backgroundImage:  (_img != null)?_img!.image:null,
                  ),
                ),
                MaterialButton(
                    onPressed: () async{
                      await _upload(widget.argumentUserData["userDocId"]!);
                      await _download(widget.argumentUserData["userDocId"]!);
                      setState(()  {

                      });
                    },
                    child: const Text('写真アップロード') //,
                ),
                linePadding("Name","name", widget.argumentUserData["name"]!),
                linePadding("E-mail","email", widget.argumentUserData["email"]!),
                linePadding("Age","age", widget.argumentUserData["age"]!),
                linePadding("English Level","level", widget.argumentUserData["level"]!),
                linePadding("Occupation","occupation", widget.argumentUserData["occupation"]!),
                linePadding("mother Tongue","nativeLang", widget.argumentUserData["nativeLang"]!),
                linePadding("Country","country", widget.argumentUserData["country"]!),
                linePadding("Town","town", widget.argumentUserData["town"]!),
                linePadding("Home Country","homeCountry", widget.argumentUserData["homeCountry"]!),
                linePadding("Home Town","homeTown", widget.argumentUserData["homeTown"]!),
                linePadding("gender","gender", widget.argumentUserData["gender"]!),
                linePadding("Place I wanna go","placeWannaGo", widget.argumentUserData["placeWannaGo"]!),
                linePadding("Greeting","greeting", widget.argumentUserData["greeting"]!),
                linePadding("Description","description", widget.argumentUserData["description"]!),


          ])),
        ));
  }


  Padding linePadding (String displayedItem,String databaseItem, String value) {
    //valueType:String or int or selectString(セグメント)
    String displayedValue;
    if(databaseItem=="gender"
    ||databaseItem=="level"){
      displayedValue=widget.argumentMasterData[databaseItem+"_"+value]!;
    }else{
      displayedValue=value;
    }
    return Padding(
        padding: const EdgeInsets.only(left:14,right:14,bottom:10),
        child: Container(
          height: 52,
          child:Column(children:[
            Container(
              width: double.infinity,
              child: Text(
                displayedItem,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                  color: Colors.deepOrange,
                ),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(displayedValue,
                style: TextStyle(
                fontWeight: FontWeight.normal,
                  fontSize: 18,
                  color: Colors.black87,
                ),),

            Padding(padding:const EdgeInsets.only(left:5),
              child:GestureDetector(
                          onTap: () async{
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) {
                                return SettingEditPage(
                                    argumentUserData: widget.argumentUserData,
                                    argumentMasterData:widget.argumentMasterData ,
                                    displayedItem: displayedItem,
                                    databaseItem: databaseItem,
                                    value:value,
                                );
                              }),
                            );
                            setState(()  {

                            });//TODO FutureBuilderを使用するようにして非同期のデータ取得のあとSetStateするダサい処理を削除したい
                          },
                          child: Icon(
                            Icons.edit,
                            color: Colors.black87,
                            size:18
                          )
                      ),)]),
              )
            ]),
          ]),
          decoration: BoxDecoration(
            border: const Border(
              bottom: const BorderSide(
                color: Colors.black26,
                width: 0.5,
              ),
            ),
          ),
        ));
  }
}
