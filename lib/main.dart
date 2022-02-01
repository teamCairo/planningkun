// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_config.dart';
import 'tabs_page.dart';
import 'login.dart';
import 'rootWidget.dart';
import 'common.dart';
import 'database.dart';
import 'common.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseConfig.platformOptions);
  await Hive.initFlutter();
  Hive.registerAdapter(UserDataAdapter());


  //Hive.registerAdapter(RecordModelAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
  FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      navigatorObservers: <NavigatorObserver>[observer],
      home: MyHomePage(
        title: 'Firebase Analytics Demo',
        analytics: analytics,
        observer: observer,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    Key? key,
    required this.title,
    required this.analytics,
    required this.observer,
  }) : super(key: key);

  final String title;
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _message = '';
  String email = '';
  String userDocId = '';
  // 入力されたパスワード
  String password = "";
  // 登録・ログインに関する情報を表示
  String infoText = "";
  UserInfoData userData =UserInfoData();
  Map<String,String> masterData={};


  List<String> _contents=[];
  @override
  void initState(){
  }

  Future<void> _insertUserAndMove(String email) async {

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();


    if(snapshot.size==0){
      FirebaseFirestore.instance.collection('users').add(
      {'email':email ,
      'name': "テスト用",
      'age':21 ,
      'level':"1",
      'occupation':'consultant',
      'nativeLang':"JPN",
      'country':"JPN",
      'town':"Tokyo",
      'homeCountry':"JPN",
      'homeTown':"Nagano",
      'gender':1,
      'placeWannaGo':'antarctic',
      'greeting':'おはようございます！',
      'description':'わたしは～～～'
      },
      );


      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      userDocId=snapshot.docs[0].id;

      //Hiveボックスをオープン
      var box = await Hive.openBox('record');

      //TODO　もともとのユーザとことなるユーザがログインされたら、警告を出して、リセット
      //TODO　Firebaseのデータを読み出してきて、Hiveに書き込むように変更
      await box.put("userDocId",userDocId);
      await box.put("email",email);
      await box.put("name","テスト用");
      await box.put("age",21);
      await box.put("level","1");
      await box.put("occupation","consultant");
      await box.put("nativeLang","JPN");
      await box.put("country","JPN");
      await box.put("town","Tokyo");
      await box.put("homeCountry","JPN");
      await box.put("homeTown","Nagano");
      await box.put("gender","1");
      await box.put("placeWannaGo","antarctic");
      await box.put("greeting","おはようございます");
      await box.put("description","わたしは～～～");

      //ユーザデータ型で登録するときの処理　終了


      await box.close();



    }else{

      userDocId=snapshot.docs[0].id;
    }


    //ログイン・ユーザ登録後の共通処理
    //TODO　Firebaseのデータを読み出してきて、メモリに書き込むように変更
    userData.setUserDocId(userDocId);
    userData.setEmail(email);
    userData.setName("テスト用");
    userData.setAge(21);
    userData.setLevel("1");
    userData.setOccupation("consultant");
    userData.setNativeLang("JPN");
    userData.setCountry("JPN");
    userData.setTown("Tokyo");
    userData.setHomeCountry("JPN");
    userData.setHomeTown("Nagano");
    userData.setGender("1");
    userData.setPlaceWannaGo("antarctic");
    userData.setGreeting("おはようございます");
    userData.setDescription("わたしは～～～");


    //マスタデータをFirebaseからHiveへ

    await FirebaseFirestore.instance.collection('masters').get().then((QuerySnapshot snapshot)async {

      var boxMaster = await Hive.openBox('master');
      await boxMaster.clear();
      masterData.clear();

       snapshot.docs.forEach((doc) async{

        //Hiveとメモリにデータをセットする処理を追加
        await boxMaster.put(doc.get('item')+"_"+doc.get('selectedValue'),doc.get('displayedValue'));
        masterData[doc.get('item')+"_"+doc.get('selectedValue')]=doc.get('displayedValue');
      });

      await boxMaster.close();


      // ログインに成功した場合
      // チャット画面に遷移＋ログイン画面を破棄
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) {
          return RootWidget(
            argumentUserData: userData,
            argumentMasterData: masterData);
        }),
      );
    });




  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child:Column(
        children: <Widget>[
          Container(
            child:Text("ログイン")
          ),
          TextFormField(
            // テキスト入力のラベルを設定
            decoration: InputDecoration(labelText: "メールアドレス"),
            onChanged: (String value) {
              setState(() {
                email = value;
              });
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(labelText: "パスワード（６文字以上）"),
            // パスワードが見えないようにする
            obscureText: true,
            onChanged: (String value) {
              setState(() {
                password = value;
              });
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              try {
                // メール/パスワードでユーザー登録
                final FirebaseAuth auth = FirebaseAuth.instance;
                final UserCredential result =
                await auth.createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                // 登録したユーザー情報
                final User user = result.user!;
                setState(() {
                  infoText = "登録OK：${user.email}";

                  _insertUserAndMove(email);
                });
              } catch (e) {
                // 登録に失敗した場合
                setState(() {
                  infoText = "登録NG：${e.toString()}";
                });
              }


            },
            child: Text("ユーザー登録"),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            // ログイン登録ボタン
            child: OutlinedButton(
              child: Text('ログイン'),
              onPressed: () async {
                try {
                  // メール/パスワードでログイン
                  final FirebaseAuth auth = FirebaseAuth.instance;
                  await auth.signInWithEmailAndPassword(
                    email: email,
                    password: password,
                  );
                  _insertUserAndMove(email);

                } catch (e) {
                  // ログインに失敗した場合
                  setState(() {
                    infoText = "ログインに失敗しました：${e.toString()}";
                  });
                }
              },
            ),
          ),
          Text(infoText),
          const SizedBox(height: 8),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<TabsPage>(
              settings: const RouteSettings(name: TabsPage.routeName),
              builder: (BuildContext context) {
                return TabsPage(widget.observer);
              },
            ),
          );
        },
        child: const Icon(Icons.tab),
      ),
    );
  }
}