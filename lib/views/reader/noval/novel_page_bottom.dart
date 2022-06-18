import 'dart:async';
import 'dart:math';

import 'package:battery/battery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dmzj/app/app_setting.dart';
import 'package:flutter_dmzj/app/config_helper.dart';
import 'package:flutter_dmzj/app/user_helper.dart';
import 'package:flutter_dmzj/app/user_info.dart';
import 'package:flutter_dmzj/models/novel/novel_volume_item.dart';
import 'package:flutter_dmzj/sql/novel_history.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_android_volume_keydown/flutter_android_volume_keydown.dart';
import 'package:flutter_dmzj/views/reader/noval/novel_reader_page.dart';
import 'package:flutter_dmzj/views/reader/noval/novel_page_data.dart';

class NovelPageBottom extends StatefulWidget {
  final int novelId;
  final NovelReaderContent content;

  NovelPageBottom({this.novelId, this.content, key}) : super(key: key);

  @override
  _NovelPageBottomState createState() => _NovelPageBottomState();
}

class _NovelPageBottomState extends State<NovelPageBottom> {
  NovelReaderContent content;

  @override
  void initState() {
    super.initState();
    content = widget.content;
  }

  @override
  Widget build(BuildContext context) {
    var showControls = getNovelPageData(context).showControls;

    return AnimatedPositioned(
      duration: Duration(milliseconds: 200),
      width: MediaQuery.of(context).size.width,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        width: MediaQuery.of(context).size.width,
        color: Color.fromARGB(255, 34, 34, 34),
        child: Column(
          children: <Widget>[
            buildBottomBarTopRow(),
            buildBottomBarButtomRow(),
            SizedBox(height: 36)
          ],
        ),
      ),
      bottom: showControls ? 0 : -180,
      left: 0,
    );
  }

  Widget buildBottomBarTopRow() {
    var _verSliderValue = getNovelPageData(context).verSliderValue;
    var _verSliderMax = getNovelPageData(context).verSliderMax;
    var indexPage = getNovelPageData(context).indexPage;
    var controllerVer = getNovelPageData(context).controllerVer;
    var controller = getNovelPageData(context).controller;

    var sliderContent;
    var onChanged;
    var maxValue;
    double value;
    if (!getNovelPageData(context).loading) {
      if (Provider.of<AppSetting>(context).novelReadDirection == 2) {
        value = _verSliderValue;
        maxValue = _verSliderMax;
        onChanged = (e) {
          mainEvent.fire(EventType(eventType.jumpToVer, page: e));
        };
      } else {
        value = indexPage >= 1 ? indexPage - 1.toDouble() : 0;
        maxValue = max(
            getNovelPageData(context).pageContents.length - 1.toDouble(),
            value);
        onChanged = (e) {
          setState(() {
            getNovelPageData(context, listen: false)
                .changeIndexPage(e.toInt() + 1);
            mainEvent.fire(EventType(eventType.jumpTo, page: e + 1));
          });
        };
      }

      sliderContent = Expanded(
          child: Slider(
        value: value,
        max: maxValue,
        onChanged: onChanged,
      ));
    } else {
      sliderContent = Text(
        "加载中",
        style: TextStyle(color: Colors.white),
      );
    }

    return Row(
      children: <Widget>[
        buildChangeChapterButton(
            (() => mainEvent.fire(EventType(eventType.previousChapter))),
            "上一话"),
        sliderContent,
        buildChangeChapterButton(
            (() => mainEvent.fire(EventType(eventType.nextChapter))), "下一话")
      ],
    );
  }

  // 创建切换章节按钮
  Widget buildChangeChapterButton(onPressed, textStr) {
    return ButtonTheme(
      minWidth: 10,
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          textStr,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget buildBottomBarButtomRow() {
    var _subscribe = getNovelPageData(context).subscribe;
    return Row(
      children: <Widget>[
        Provider.of<AppUserInfo>(context).isLogin && _subscribe
            ? createButton(
                "已订阅",
                Icons.favorite,
                onTap: () async {
                  if (await UserHelper.novelSubscribe(widget.novelId,
                      cancel: true)) {
                    setState(() {
                      _subscribe = false;
                    });
                  }
                },
              )
            : createButton(
                "订阅",
                Icons.favorite_border,
                onTap: () async {
                  if (await UserHelper.novelSubscribe(widget.novelId)) {
                    setState(() {
                      _subscribe = true;
                    });
                  }
                },
              ),
        createButton("设置", Icons.settings, onTap: openSetting),
        createButton("章节", Icons.format_list_bulleted, onTap: () {
          setState(() {
            getNovelPageData(context, listen: false).changeShowChapters(true);
          });
        }),
      ],
    );
  }

  Widget createButton(String text, IconData icon, {Function onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              children: <Widget>[
                Icon(icon, color: Colors.white),
                SizedBox(
                  height: 4,
                ),
                Text(
                  text,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 打开设置弹窗
  void openSetting() {
    var size = Provider.of<AppSetting>(context, listen: false).novelFontSize;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Color.fromARGB(255, 34, 34, 34),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 80,
                    child: Text(
                      "字号",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: createOutlineButton("小", onPressed: () async {
                      if (size == 10) {
                        Fluttertoast.showToast(msg: '不能再小了');
                        return;
                      }
                      Provider.of<AppSetting>(context, listen: false)
                          .changeNovelFontSize(size - 1);
                      mainEvent.fire(EventType(eventType.handleContent));
                    }),
                  ),
                  SizedBox(
                    width: 24,
                  ),
                  Expanded(
                    child: createOutlineButton("大", onPressed: () async {
                      if (size == 30) {
                        Fluttertoast.showToast(msg: '不能再大了');
                        return;
                      }
                      Provider.of<AppSetting>(context, listen: false)
                          .changeNovelFontSize(size + 1);
                      mainEvent.fire(EventType(eventType.handleContent));
                    }),
                  )
                ],
              ),
              Row(
                children: <Widget>[
                  Container(
                    width: 80,
                    child: Text(
                      "行距",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: createOutlineButton("减少", onPressed: () async {
                      var height =
                          Provider.of<AppSetting>(context, listen: false)
                              .novelLineHeight;
                      if (height == 0.8) {
                        Fluttertoast.showToast(msg: '不能再减少了');
                        return;
                      }
                      Provider.of<AppSetting>(context, listen: false)
                          .changeNovelLineHeight(height - 0.1);
                      mainEvent.fire(EventType(eventType.handleContent));
                    }),
                  ),
                  SizedBox(
                    width: 24,
                  ),
                  Expanded(
                    child: createOutlineButton("增加", onPressed: () async {
                      var height =
                          Provider.of<AppSetting>(context, listen: false)
                              .novelLineHeight;
                      if (height == 2.0) {
                        Fluttertoast.showToast(msg: '不能再增加了');
                        return;
                      }
                      Provider.of<AppSetting>(context, listen: false)
                          .changeNovelLineHeight(height + 0.1);
                      mainEvent.fire(EventType(eventType.handleContent));
                    }),
                  )
                ],
              ),
              Row(
                children: <Widget>[
                  Container(
                    width: 80,
                    child: Text(
                      "方向",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: createOutlineButton("左右",
                        borderColor: Provider.of<AppSetting>(context)
                                    .novelReadDirection ==
                                0
                            ? Colors.blue
                            : null, onPressed: () {
                      Provider.of<AppSetting>(context, listen: false)
                          .changeNovelReadDirection(0);
                    }),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: createOutlineButton("右左",
                        borderColor: Provider.of<AppSetting>(context)
                                    .novelReadDirection ==
                                1
                            ? Colors.blue
                            : null, onPressed: () {
                      Provider.of<AppSetting>(context, listen: false)
                          .changeNovelReadDirection(1);
                    }),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: createOutlineButton("上下",
                        borderColor: Provider.of<AppSetting>(context)
                                    .novelReadDirection ==
                                2
                            ? Colors.blue
                            : null, onPressed: () {
                      Provider.of<AppSetting>(context, listen: false)
                          .changeNovelReadDirection(2);
                    }),
                  )
                ],
              ),
              SizedBox(
                height: 8,
              ),
              Row(
                children: <Widget>[
                  Container(
                    width: 80,
                    child: Text(
                      "主题",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: createOutlineButtonColor(AppSetting.bgColors[0],
                        borderColor:
                            Provider.of<AppSetting>(context).novelReadTheme == 0
                                ? Colors.blue
                                : null, onPressed: () {
                      Provider.of<AppSetting>(context, listen: false)
                          .changeNovelReadTheme(0);
                    }),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: createOutlineButtonColor(AppSetting.bgColors[1],
                        borderColor:
                            Provider.of<AppSetting>(context).novelReadTheme == 1
                                ? Colors.blue
                                : null, onPressed: () {
                      Provider.of<AppSetting>(context, listen: false)
                          .changeNovelReadTheme(1);
                    }),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: createOutlineButtonColor(AppSetting.bgColors[2],
                        borderColor:
                            Provider.of<AppSetting>(context).novelReadTheme == 2
                                ? Colors.blue
                                : null, onPressed: () {
                      Provider.of<AppSetting>(context, listen: false)
                          .changeNovelReadTheme(2);
                    }),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: createOutlineButtonColor(AppSetting.bgColors[3],
                        borderColor:
                            Provider.of<AppSetting>(context).novelReadTheme == 3
                                ? Colors.blue
                                : null, onPressed: () {
                      Provider.of<AppSetting>(context, listen: false)
                          .changeNovelReadTheme(3);
                    }),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget createOutlineButton(String text,
      {Function onPressed, Color borderColor}) {
    if (borderColor == null) {
      borderColor = Colors.grey.withOpacity(0.6);
    }

    var style = ButtonStyle(
        side: MaterialStateProperty.resolveWith<BorderSide>(
            (Set<MaterialState> states) =>
                BorderSide(color: Colors.white.withOpacity(0.6))));
    var textItem = Text(
      text,
      style: TextStyle(color: Colors.white),
    );
    return OutlinedButton(
      style: style,
      child: textItem,
      onPressed: onPressed,
    );
  }

  Widget createOutlineButtonColor(Color color,
      {Function onPressed, Color borderColor}) {
    if (borderColor == null) {
      borderColor = Colors.grey.withOpacity(0.6);
    }
    return InkWell(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          color: color,
        ),
        height: 32,
      ),
      onTap: onPressed,
    );
  }
}
