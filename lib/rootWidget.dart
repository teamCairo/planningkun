import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:planningkun/routes/myPage_route.dart';

// == 作成したWidget をインポート ==================
import 'routes/myPage_route.dart';
import 'routes/talk_route.dart';
import 'routes/search_route.dart';
import 'routes/mapPage_route.dart';
import 'routes/setting_route.dart';
import 'routes/topic_route.dart';
import 'routes/now_route.dart';
import 'common.dart';
import 'dart:core';
import 'join_channel_video.dart';
// =============================================

class RootWidget extends StatefulWidget {
  Map<String,String>  argumentUserData;
  Map<String, String> argumentMasterData;
  Map<String,Map<String,String>>  argumentFriendData;
  Image? argumentMainPhotoData;

  RootWidget({required this.argumentUserData,required this.argumentMasterData,required this.argumentFriendData, required this.argumentMainPhotoData});

  @override
  _RootWidgetState createState() => _RootWidgetState();
}

class _RootWidgetState extends State<RootWidget> {
  int _selectedIndex = 0;
  final _bottomNavigationBarItems = <BottomNavigationBarItem>[];

  static const _footerIcons = [
    Icons.access_time,
    Icons.textsms,
    Icons.search,
    Icons.wallpaper_sharp,
    Icons.work_outline,
  ];

  static const _footerItemNames = [
    'Now',
    'Talk',
    'Find',
    'Topic',
    'MyPage',
  ];


  @override
  void initState() {
    super.initState();

    _bottomNavigationBarItems.add(_UpdateActiveState(0));
    for (var i = 1; i < _footerItemNames.length; i++) {
      _bottomNavigationBarItems.add(_UpdateDeactiveState(i));
    }
  }

  /// インデックスのアイテムをアクティベートする
  BottomNavigationBarItem _UpdateActiveState(int index) {
    return BottomNavigationBarItem(
        icon: Icon(
          _footerIcons[index],
          color: Colors.black87,
        ),
        title: Text(
          _footerItemNames[index],
          style: TextStyle(
            color: Colors.black87,
          ),
        ));
  }

  BottomNavigationBarItem _UpdateDeactiveState(int index) {
    return BottomNavigationBarItem(
        icon: Icon(
          _footerIcons[index],
          color: Colors.black26,
        ),
        title: Text(
          _footerItemNames[index],
          style: TextStyle(
            color: Colors.black26,
          ),
        ));
  }

  void _onItemTapped(int index) {
    setState(() {
      _bottomNavigationBarItems[_selectedIndex] =
          _UpdateDeactiveState(_selectedIndex);
      _bottomNavigationBarItems[index] = _UpdateActiveState(index);
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      routeElement(_selectedIndex,widget.argumentUserData["email"]!,widget.argumentUserData["userDocId"]!),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // これを書かないと3つまでしか表示されない
        items: _bottomNavigationBarItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget routeElement(int selectedIndex,String email,String userDocId) {
    switch (selectedIndex) {
      case 0:
        return Now(argumentUserData: widget.argumentUserData,
            argumentMasterData:widget.argumentMasterData,
            argumentFriendData:widget.argumentFriendData,
            argumentMainPhotoData:widget.argumentMainPhotoData);
      case 1:
        return Talk(argumentUserData: widget.argumentUserData,
            argumentMasterData:widget.argumentMasterData,
            argumentFriendData:widget.argumentFriendData);
        break;
      case 2:
        return Search(argumentUserData: widget.argumentUserData,
            argumentMasterData:widget.argumentMasterData,
            argumentFriendData:widget.argumentFriendData,
            argumentMainPhotoData:widget.argumentMainPhotoData);
      case 3:
        return Topic(argumentUserData: widget.argumentUserData,
            argumentMasterData:widget.argumentMasterData,
            argumentFriendData:widget.argumentFriendData,
            argumentMainPhotoData:widget.argumentMainPhotoData);
      default:
        return MyPage(argumentUserData: widget.argumentUserData,
            argumentMasterData:widget.argumentMasterData,
            argumentFriendData:widget.argumentFriendData,
            argumentMainPhotoData:widget.argumentMainPhotoData);
        break;
        //return JoinChannelVideo();

    }
  }
}
