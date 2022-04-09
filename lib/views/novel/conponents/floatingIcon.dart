import 'package:flutter/material.dart';

import 'package:flutter_dmzj/app/utils.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_dmzj/app/config_helper.dart';

class MyFloatingIcon extends FloatingActionButton {
  MyFloatingIcon(this.context, {Key key})
      : super(
          key: key,
          onPressed: null,
          child: Icon(Icons.play_arrow),
          heroTag: null,
        );

  final BuildContext context;

  @override
  VoidCallback get onPressed => openDetail;

  void openDetail() {
    var lastBook = ConfigHelper.getLastNovel();
    if (lastBook != 0) {
      Utils.openPage(context, lastBook, 2);
    } else {
      Fluttertoast.showToast(msg: '无阅读历史');
    }
  }
}
