import 'dart:async';

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
import 'package:flutter_dmzj/views/reader/noval/novel_page_bottom.dart';

class NovelReaderPage extends StatefulWidget {
  final int novelId;
  final String novelTitle;
  final List<NovelVolumeChapterItem> chapters;
  final NovelVolumeChapterItem currentItem;
  final bool subscribe;
  NovelReaderPage(
      this.novelId, this.novelTitle, this.chapters, this.currentItem,
      {this.subscribe, Key key})
      : super(key: key);

  @override
  _NovelReaderPageState createState() => _NovelReaderPageState();
}

class _NovelReaderPageState extends State<NovelReaderPage> {
  //EventBus settingEvent = EventBus();
  Battery _battery = Battery();

  String _batteryStr = "-%";
  String _timeStr = "00:00"; // 时间显示
  Timer myTimer;
  @override
  void initState() {
    super.initState();
    Provider.of<NovelPageData>(context).subscribe = widget.subscribe;
    Provider.of<NovelPageData>(context).changeCurrentItem(widget.currentItem);
    //全屏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _battery.batteryLevel.then((e) {
      setState(() {
        _batteryStr = e.toString() + "%";
        DateTime now = DateTime.now();
        _timeStr = DateFormat('HH:mm').format(now);
      });
    });

    _battery.onBatteryStateChanged.listen((BatteryState state) async {
      var e = await _battery.batteryLevel;
      setState(() {
        _batteryStr = e.toString() + "%";
        DateTime now = DateTime.now();
        _timeStr = DateFormat('HH:mm').format(now);
      });
    });

    //定时器
    myTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (!mounted) {
        return;
      }

      setState(() {
        DateTime now = DateTime.now();
        _timeStr = DateFormat('HH:mm').format(now);
      });
    });

    //刷新内容
    // settingEvent.on<double>().listen((e) async {
    //   await handelContent();
    // });

    // _controller.addListener((){
    //   print(_controller.offset);
    // });

    setReadDirection();
    startListening();
  }

  void setReadDirection() {
    setState(() {
      Provider.of<NovelPageData>(context)
          .changeReadDirection(ConfigHelper.getNovelReadDirection());
    });
  }

  @override
  void dispose() {
    var _verSliderValue = Provider.of<NovelPageData>(context).verSliderValue;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    var readDirection = Provider.of<NovelPageData>(context).readDirection;
    var _currentItem = Provider.of<NovelPageData>(context).currentItem;
    var _indexPage = Provider.of<NovelPageData>(context).indexPage;

    if (readDirection == 2) {
      NovelHistoryProvider.updateOrCreate(NovelHistory(
          widget.novelId, _currentItem.chapter_id, _verSliderValue, 2));
    } else {
      NovelHistoryProvider.updateOrCreate(NovelHistory(widget.novelId,
          _currentItem.chapter_id, _indexPage.toDouble(), readDirection));
    }

    UserHelper.comicAddNovelHistory(
        widget.novelId, _currentItem.volume_id, _currentItem.chapter_id,
        page: _indexPage);
    subscription?.cancel();
    myTimer?.cancel();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void startListening() {
    subscription = FlutterAndroidVolumeKeydown.stream.listen((event) {
      if (event == HardwareButton.volume_down) {
        print("Volume down received");
        content.nextPage.fire(event);
      } else if (event == HardwareButton.volume_up) {
        print("Volume up received");
        content.previousPage.fire(event);
      }
    });
  }

  StreamSubscription<HardwareButton> subscription;

  NovelReaderContent content;
  @override
  Widget build(BuildContext context) {
    content = NovelReaderContent(
      widget.novelId,
      widget.novelTitle,
      widget.chapters,
      widget.currentItem,
    );
    var goLeft;
    var goRight;
    var buttomText;

    if (Provider.of<AppSetting>(context).novelReadDirection == 2) {
      goLeft = Positioned(
        left: 0,
        width: 40,
        height: MediaQuery.of(context).size.height,
        child: InkWell(
          onTap: () {
            if (Provider.of<AppSetting>(context, listen: false)
                    .novelReadDirection ==
                1) {
              content.nextPage.fire(ChangePage());
            } else {
              content.previousPage.fire(ChangePage());
            }
          },
          child: Container(),
        ),
      );

      goRight = Positioned(
        right: 0,
        width: 40,
        height: MediaQuery.of(context).size.height,
        child: InkWell(
          onTap: () {
            if (Provider.of<AppSetting>(context, listen: false)
                    .novelReadDirection ==
                1) {
              content.previousPage.fire(ChangePage());
            } else {
              content.nextPage.fire(ChangePage());
            }
          },
          child: Container(),
        ),
      );

      var _indexPage = Provider.of<NovelPageData>(context).indexPage;
      var length = Provider.of<NovelPageData>(context).pageContents.length;
      buttomText = "$_indexPage/$length $_batteryStr电量 $_timeStr";
    } else {
      goLeft = Positioned(child: Container());
      goRight = Positioned(child: Container());
      buttomText = "";
    }

    // 阅读页面底部系统信息文字
    var buttomTextItem = Positioned(
        bottom: 8,
        right: 12,
        child: Text(
          buttomText,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ));

    var loadingIndicator = Positioned(
      top: 80,
      width: MediaQuery.of(context).size.width,
      child: Provider.of<NovelPageData>(context).loading
          ? Container(
              width: double.infinity,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : Container(),
    );

    return Scaffold(
      backgroundColor:
          AppSetting.bgColors[Provider.of<AppSetting>(context).novelReadTheme],
      body: Stack(
        children: <Widget>[
          content,
          goLeft,
          goRight,
          buttomTextItem,
          //加载
          loadingIndicator,
          //顶部
          buildTopBar(),
          //底部
          NovelPageBottom(
            novelId: widget.novelId,
            content: content,
          ),
          //右侧章节选择
          buildRightBar()
        ],
      ),
    );
  }

  Widget buildTopBar() {
    var currentItem = Provider.of<NovelPageData>(context).currentItem;
    return AnimatedPositioned(
      duration: Duration(milliseconds: 200),
      width: MediaQuery.of(context).size.width,
      child: Container(
        padding: EdgeInsets.only(
            top: Provider.of<AppSetting>(context).comicReadShowStatusBar
                ? 0
                : MediaQuery.of(context).padding.top),
        width: MediaQuery.of(context).size.width,
        child: Material(
            color: Color.fromARGB(255, 34, 34, 34),
            child: ListTile(
              dense: true,
              title: Text(
                widget.novelTitle,
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                currentItem.volume_name.trim() +
                    " · " +
                    currentItem.chapter_name.trim(),
                style: TextStyle(color: Colors.white),
              ),
              leading: BackButton(
                color: Colors.white,
              ),
              trailing: IconButton(
                  icon: Icon(
                    Icons.share,
                    color: Colors.white,
                  ),
                  onPressed: () {}),
            )),
      ),
      top: Provider.of<NovelPageData>(context).showControls ? 0 : -100,
      left: 0,
    );
  }

  Widget buildRightBar() {
    var currentItem = Provider.of<NovelPageData>(context).currentItem;
    var showChapters = Provider.of<NovelPageData>(context).showChapters;

    return AnimatedPositioned(
      duration: Duration(milliseconds: 200),
      width: 200,
      child: Container(
          height: MediaQuery.of(context).size.height,
          color: Color.fromARGB(255, 24, 24, 24),
          padding: EdgeInsets.only(
              top: Provider.of<AppSetting>(context).comicReadShowStatusBar
                  ? 0
                  : MediaQuery.of(context).padding.top),
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    "目录(${widget.chapters.length})",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  )),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.chapters.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      var item = widget.chapters[i];
                      return Text(item.volume_name);
                    } else {
                      var item = widget.chapters[i - 1];

                      return ListTile(
                        dense: true,
                        onTap: () async {
                          var _currentItem = currentItem;
                          if (item != _currentItem) {
                            setState(() {
                              Provider.of<NovelPageData>(context)
                                  .changeCurrentItem(item);
                              Provider.of<NovelPageData>(context).showChapters =
                                  false;
                              Provider.of<NovelPageData>(context).showControls =
                                  false;
                            });

                            content.loadData.fire(ChangePage());
                          }
                        },
                        title: Text(
                          item.chapter_name,
                          style: TextStyle(
                              color: item == currentItem
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.white),
                        ),
                        // subtitle: Text(
                        //   item.volume_name,
                        //   style: TextStyle(color: Colors.grey),
                        // ),
                      );
                    }
                  },
                  separatorBuilder: (context, i) {
                    if (i != 0) {
                      var item = widget.chapters[i];
                      if (i + 1 < widget.chapters.length) {
                        var nextItem = widget.chapters[i + 1];

                        if (nextItem.volume_id != item.volume_id) {
                          return Text(nextItem.volume_name);
                        }
                      }
                    }
                    return Divider();
                  },
                ),
              ),
            ],
          )),
      top: 0,
      right: showChapters ? 0 : -200,
    );
  }
}
