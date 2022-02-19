
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'commonEntity/friendEntity.dart';
import 'commonEntity/masterEntity.dart';
import 'commonEntity/topicEntity.dart';
import 'commonEntity/userData.dart';
import 'commonLogic/commonLogic.dart';
import 'rootWidget.dart';
import 'commonEntity/commonEntity.dart';


class AutoLoginPage extends ConsumerWidget  {
  AutoLoginPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Providerから値を受け取る
    autoLoginProcess(context,ref);

    return Scaffold(
      body: SafeArea(
        child:Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:[
          Center(
            child: Container(
                child: Text(
                  "Logo",
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 90,
                    color: Colors.black87,
                  ),
                ),),
          ),
          const SizedBox(height: 30),
          Center(
            child: Container(
              child: Text(
                "logging in",
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),),
          ),
        ])
      ),
    );
  }

  Future<void> autoLoginProcess(BuildContext context, WidgetRef ref)async{

    var box = await Hive.openBox('record');
    await initialProcessLogic(ref,await box.get("email"));


    // ログインに成功した場合
    // チャット画面に遷移＋ログイン画面を破棄
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) {
        return RootWidget();
      }),
    );

  }



}