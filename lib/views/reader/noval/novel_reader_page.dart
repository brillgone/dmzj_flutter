import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:ui';
import 'dart:typed_data';

import 'package:html_unescape/html_unescape.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_dmzj/app/api/novel.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dmzj/app/utils.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dmzj/app/app_setting.dart';
import 'package:flutter_dmzj/sql/novel_history.dart';
import 'package:flutter_dmzj/app/config_helper.dart';
import 'package:flutter_dmzj/views/reader/noval/novel_page_data.dart';

import 'package:flutter_dmzj/models/novel/novel_volume_item.dart';

import 'dart:async';

import 'package:flutter_dmzj/app/user_helper.dart';

import 'package:fluttertoast/fluttertoast.dart';

import 'package:event_bus/event_bus.dart';

class NovelReaderContent extends StatefulWidget {
  NovelReaderContent(
      this.novelId, this.novelTitle, this.chapters, this.currentItem,
      {Key key})
      : super(key: key);

  final int novelId;
  final String novelTitle;
  final List<NovelVolumeChapterItem> chapters;
  final NovelVolumeChapterItem currentItem;

  @override
  NovelReaderContentState createState() => NovelReaderContentState();
}

class NovelReaderContentState extends State<NovelReaderContent> {
  double _fontSize = 16.0;
  double _lineHeight = 1.5;

  bool _isPicture = false;

  Uint8List _contents;

  StreamSubscription<ChangePage> pagechangeEvent;
  StreamSubscription<EventType> eventRunnter;

  var _controllerVer = ScrollController();
  var _controller = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();

    initEvent();

    _controllerVer.addListener(() {
      var value = _controllerVer.offset;
      if (value < 0) {
        value = 0;
      }
      if (value > _controllerVer.position.maxScrollExtent) {
        value = _controllerVer.position.maxScrollExtent;
      }
      setState(() {
        getNovelPageData(context, listen: false).verSliderMax =
            _controllerVer.position.maxScrollExtent;
        getNovelPageData(context, listen: false).changeVerSliderValue(value);
      });
    });

    WidgetsBinding.instance.addPostFrameCallback(((timeStamp) => loadData(1)));
  }

  @override
  void dispose() {
    super.dispose();

    pagechangeEvent.cancel();
    eventRunnter.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var child;
    if (Provider.of<AppSetting>(context).novelReadDirection != 2) {
      child = buildPageView();
    } else {
      child = buildEasyRefresh();
    }

    var onTap = () {
      var _showChapters = getNovelPageData(context, listen: false).showChapters;
      setState(() {
        if (_showChapters) {
          getNovelPageData(context, listen: false).changeShowChapters(false);
          return;
        }
        getNovelPageData(context, listen: false).changeShowControls(
            !getNovelPageData(context, listen: false).showControls);
      });
    };

    return InkWell(
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: onTap,
        child: child);
  }

  // 左右滑动页面
  Widget buildPageView() {
    // 横向页面滑动事件
    var onPageChanged = (int page) {
      var _loading = getNovelPageData(context, listen: false).loading;
      if (page ==
              getNovelPageData(context, listen: false).pageContents.length +
                  1 &&
          !_loading) {
        nextChapter(1);
        return;
      }
      if (page == 0 && !_loading) {
        print("slide previous page:$page");
        previousChapter(1);
        return;
      }

      print("setState page:$page");
      if (page <
          getNovelPageData(context, listen: false).pageContents.length + 1) {
        setState(() {
          print("setState page:$page");
          // print("setState indexPage:$_indexPage");
          getNovelPageData(context, listen: false).changeIndexPage(page);
          var readDirection = ConfigHelper.getNovelReadDirection();
          var _currentItem =
              getNovelPageData(context, listen: false).currentItem;
          NovelHistoryProvider.updateOrCreate(NovelHistory(widget.novelId,
              _currentItem.chapter_id, page.toDouble(), readDirection));
          // ConfigHelper.setCurrentPage(
          //     widget.novelId, _currentItem.chapter_id, i);
        });
      }
    };

    return PageView.builder(
        //左右滑动模式
        scrollDirection: Axis.horizontal,
        pageSnapping: Provider.of<AppSetting>(context).novelReadDirection != 2,
        controller: _controller,
        itemCount: getNovelPageData(context).pageContents.length + 2,
        reverse: Provider.of<AppSetting>(context).novelReadDirection == 1,
        onPageChanged: onPageChanged,
        itemBuilder: buildContainer);
  }

  // 左右滑动阅读界面内容
  Widget buildContainer(BuildContext ctx, int i) {
    var _pageContents = getNovelPageData(context).pageContents;
    var _widget;
    if (i == 0) {
      _widget = Container(
        child: Center(child: Text("上一章", style: TextStyle(color: Colors.grey))),
      );
    } else if (i == _pageContents.length + 1) {
      _widget = Container(
        child: Center(child: Text("下一章", style: TextStyle(color: Colors.grey))),
      );
    } else {
      var content;
      var padding;
      var aligment;
      var mainFontColor = AppSetting
          .fontColors[Provider.of<AppSetting>(context).novelReadTheme];
      var mainBgColor =
          AppSetting.bgColors[Provider.of<AppSetting>(context).novelReadTheme];

      if (_isPicture) {
        var onDoubleTap = () {
          Utils.showImageViewDialog(
              context, _pageContents.length == 0 ? "" : _pageContents[i - 1]);
        };

        var onLongPress = () {
          Utils.showImageViewDialog(
              context, _pageContents.length == 0 ? "" : _pageContents[i - 1]);
        };

        var onTap = () {
          var _showChapters =
              getNovelPageData(context, listen: false).showChapters;
          setState(() {
            if (_showChapters) {
              getNovelPageData(context, listen: false)
                  .changeShowChapters(false);
              return;
            }
            getNovelPageData(context, listen: false).changeShowControls(
                !getNovelPageData(context, listen: false).showControls);
          });
        };

        var inkWellChild = Utils.createCacheImage(
            _pageContents[i - 1], 100, 100,
            fit: BoxFit.fitWidth);

        content = InkWell(
          onDoubleTap: onDoubleTap,
          onLongPress: onLongPress,
          onTap: onTap,
          child: inkWellChild,
        );
      } else {
        var textdata = _pageContents.length == 0 ? "" : _pageContents[i - 1];
        content = Text(
          textdata,
          style: TextStyle(
              fontSize: _fontSize, height: _lineHeight, color: mainFontColor),
        );

        padding = EdgeInsets.fromLTRB(12, 12, 12, 24);
        aligment = Alignment.topCenter;
      }

      _widget = Container(
        color: mainBgColor,
        padding: padding,
        alignment: aligment,
        child: content,
      );
    }

    return _widget;
  }

  // 上下滑动界面
  Widget buildEasyRefresh() {
    return EasyRefresh(
      taskIndependence: true,
      //上下翻滚模式
      onRefresh: () async {
        previousChapter(1);
      },
      onLoad: () async {
        nextChapter(1);
      },
      header: MaterialHeader(),
      footer: MaterialFooter(enableInfiniteLoad: false), // 关闭无限刷新防止触底就翻页
      child: SingleChildScrollView(
        controller: _controllerVer,
        child: _isPicture
            ? Column(
                // 插图
                children: getNovelPageData(context)
                    .pageContents
                    .map((f) => InkWell(
                          onDoubleTap: () {
                            Utils.showImageViewDialog(context, f);
                          },
                          onLongPress: () {
                            Utils.showImageViewDialog(context, f);
                          },
                          onTap: () {
                            var _showChapters =
                                getNovelPageData(context, listen: false)
                                    .showChapters;
                            setState(() {
                              if (_showChapters) {
                                getNovelPageData(context, listen: false)
                                    .changeShowChapters(false);
                                return;
                              }
                              getNovelPageData(context, listen: false)
                                  .changeShowControls(
                                      !getNovelPageData(context, listen: false)
                                          .showControls);
                            });
                          },
                          child: Utils.createCacheImage(f, 100, 100),
                        ))
                    .toList(),
              )
            : Container(
                // 正文
                alignment: Alignment.topCenter,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                color: AppSetting
                    .bgColors[Provider.of<AppSetting>(context).novelReadTheme],
                padding: EdgeInsets.fromLTRB(12, 12, 12, 24),
                child: Text(getNovelPageData(context).pageContents.join(),
                    style: TextStyle(
                        fontSize: _fontSize,
                        height: _lineHeight,
                        color: AppSetting.fontColors[
                            Provider.of<AppSetting>(context).novelReadTheme])),
              ),
      ),
    );
  }

  DefaultCacheManager _cacheManager = DefaultCacheManager();
  // 加载数据
  Future loadData(event, {bool toEnd = false, bool toStart = false}) async {
    var _loading = getNovelPageData(context, listen: false).loading;

    try {
      if (_loading) {
        return;
      } else {
        getNovelPageData(context, listen: false).loading = true;
      }
      setState(() {
        getNovelPageData(context, listen: false).changePageContents(["加载中"]);
      });

      var _currentItem = getNovelPageData(context, listen: false).currentItem;
      //检查缓存
      var url = NovelApi.instance.getNovelContentUrl(
          widget.novelId, _currentItem.volume_id, _currentItem.chapter_id);
      // print("url:" + url);
      var file = await _cacheManager.getFileFromCache(url);
      if (file == null) {
        file = await _cacheManager.downloadFile(url);
      }

      //var response = await http.get(url);
      var bodyBytes = await file.file.readAsBytes();
      if (String.fromCharCodes(bodyBytes.take(200))
          .contains(RegExp('<img.*?'))) {
        // print("image");
        var str = Utf8Decoder().convert(bodyBytes);
        List<String> imgs = [];
        for (var item
            in RegExp(r'<img.*?src=[' '""](.*?)[' '""].*?>').allMatches(str)) {
          // print(item.group(1));
          imgs.add(item.group(1));
        }
        _contents = Uint8List(0);
        setState(() {
          _isPicture = true;
          getNovelPageData(context, listen: false).changePageContents(imgs);
        });
      } else {
        // var str = String.fromCharCodes(bodyBytes.take(200));
        // print("text:$str");
        setState(() {
          _isPicture = false;
        });
        _contents = bodyBytes;

        await handleContent(1);
      }

      this.toEnd(toEnd, toStart);

      ConfigHelper.setNovelHistory(widget.novelId, _currentItem.chapter_id);
      UserHelper.comicAddNovelHistory(
          widget.novelId, _currentItem.volume_id, _currentItem.chapter_id);
    } catch (e) {
      print("novel_reader Exception:");
      print(e);
    } finally {
      setState(() {
        _loading = false;
        getNovelPageData(context, listen: false).loading = false;
      });
    }
  }

  void toEnd(bool toEnd, bool toStart) async {
    var _currentItem = getNovelPageData(context, listen: false).currentItem;
    var readDirection = ConfigHelper.getNovelReadDirection();

    if (readDirection == 2) {
      // 上下阅读
      if (toEnd) {
        // 跳转到尾页
        print("toEnd");

        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          var toPage = _controllerVer.position.maxScrollExtent; // 减去屏幕高度
          // print("toPage:$toPage");
          // print("_verSliderMax:$_verSliderMax");
          _controllerVer.jumpTo(toPage);
          var _verSliderValue =
              getNovelPageData(context, listen: false).verSliderValue;
          NovelHistoryProvider.updateOrCreate(NovelHistory(widget.novelId,
              _currentItem.chapter_id, _verSliderValue, readDirection));
        });
      } else if (!toStart) {
        // 跳转到上次阅读页面
        var novelItem = await NovelHistoryProvider.getItem(widget.novelId);
        if (novelItem.chapterId == _currentItem.chapter_id &&
            novelItem.mode == readDirection) {
          var oldPage = novelItem.page;
          _controllerVer.jumpTo(oldPage);
          // print("oldPage:$oldPage");
        }
      } else {
        try {
          _controllerVer.jumpTo(0);
        } catch (e) {}
      }
    } else {
      // 左右阅读
      if (toEnd) {
        // 跳转到尾页
        print("toEnd");
        var toPage =
            getNovelPageData(context, listen: false).pageContents.length;
        _controller.jumpToPage(toPage);
        getNovelPageData(context, listen: false)
            .changeIndexPage(toPage); // 未知原因导致跳页后onPageChanged返回index一直是2
        NovelHistoryProvider.updateOrCreate(NovelHistory(widget.novelId,
            _currentItem.chapter_id, toPage.toDouble(), readDirection));
      } else if (!toStart) {
        // 跳转到上次阅读页面
        var novelItem = await NovelHistoryProvider.getItem(widget.novelId);
        if (novelItem?.chapterId == _currentItem.chapter_id &&
            novelItem.mode == readDirection) {
          var oldPage = (novelItem.page).floor();
          // ConfigHelper.getCurrentPage(widget.novelId, _currentItem.chapter_id);
          _controller.jumpToPage(oldPage);
          getNovelPageData(context, listen: false).changeIndexPage(oldPage);
          // print("oldPage:$oldPage");
          // print("indexPage:$_indexPage");
        } else {
          getNovelPageData(context, listen: false).changeIndexPage(1);
        }
      } else {
        try {
          _controller.jumpToPage(1);
        } catch (e) {}
      }
    }
  }

  Future handleContent(event) async {
    if (_isPicture) {
      return;
    }
    var i = DateTime.now().millisecondsSinceEpoch;
    var width = window.physicalSize.width / window.devicePixelRatio;

    var height = window.physicalSize.height / window.devicePixelRatio;
    var par = ComputeParameter(_contents, width, height,
        ConfigHelper.getNovelFontSize(), ConfigHelper.getNovelLineHeight());
    var ls = await compute(computeContent, par);

    setState(() {
      getNovelPageData(context, listen: false).changePageContents(ls);

      _fontSize = ConfigHelper.getNovelFontSize();
      _lineHeight = ConfigHelper.getNovelLineHeight();
    });
    print("加载用时(微秒):" + (DateTime.now().millisecondsSinceEpoch - i).toString());
  }

  static List<String> computeContent(ComputeParameter par) {
    var width = par.width;

    var height = par.height;
    var _content = HtmlUnescape()
        .convert(Utf8Decoder()
            .convert(par.content)
            .replaceAll('\r\n', '\n')
            .replaceAll("<br/>", "\n")
            .replaceAll('<br />', "\n")
            .replaceAll('\n\n\n', "\n")
            .replaceAll('\n', "\n  "))
        .replaceAll("\n  \n", "\n");
    var content = toSBC(_content);

    //计算每行字数
    var maxNum = (width - 12 * 2) / par.fontSize;
    var maxNumInt = maxNum.toInt();

    //对每行字数进行添加换行符
    var result = '';
    for (var item in content.split('\n')) {
      for (var i = 0; i < item.length; i++) {
        if ((i + 1) % maxNumInt == 0 && i != item.length - 1) {
          result += item[i] + "\n";
        } else {
          result += item[i];
        }
      }
      result += '\n';
    }
    //result = result.replaceAll('\n\n' , '\n');
    //计算每页行数
    double pageLineNumDouble =
        (height - (12 * 4)) / (par.fontSize * par.lineHeight);
    //int pageLineNum=  ((height - 12 * 2) %(_fontSize * _lineHeight)==0)? pageLineNum_double.truncate():pageLineNum_double.truncate()-1;
    int pageLineNum = pageLineNumDouble.floor();
    print(pageLineNumDouble);
    print(pageLineNum);
    //计算页数
    var lines = result.split("\n");
    var maxPages = (lines.length / pageLineNum).ceil();
    //处理出每页显示的文本
    List<String> ls = [];
    for (var i = 0; i < maxPages; i++) {
      var re = "";
      for (var item in lines.skip(i * pageLineNum).take(pageLineNum)) {
        re += item + "\n";
      }
      ls.add(re);
    }
    return ls;
  }

  // 半角转全角：
  static String toSBC(String input) {
    List<int> value = [];
    var array = input.codeUnits;
    for (int i = 0; i < array.length; i++) {
      if (array[i] == 32) {
        value.add(12288);
      } else if (array[i] > 32 && array[i] <= 126) {
        value.add((array[i] + 65248));
        //value.add(array[i]);
      } else {
        value.add(array[i]);
      }
    }
    return String.fromCharCodes(value);
  }

  Duration pageChangeDura = Duration(milliseconds: 400);
  Curve curveWay = Curves.decelerate;

  void nextPage(event) {
    var _currentItem = getNovelPageData(context, listen: false).currentItem;
    var readDirection = ConfigHelper.getNovelReadDirection();
    var _indexPage = getNovelPageData(context, listen: false).indexPage;

    if (_controller.page >
        getNovelPageData(context, listen: false).pageContents.length) {
      nextChapter(1);
    } else {
      setState(() {
        var pageTo = _indexPage + 1;
        _controller.animateToPage(pageTo,
            duration: pageChangeDura, curve: curveWay);
        // ConfigHelper.setCurrentPage(
        //     widget.novelId, _currentItem.chapter_id, pageTo);
        NovelHistoryProvider.updateOrCreate(NovelHistory(
            widget.novelId, _currentItem.chapter_id, 1, readDirection));
      });
    }
  }

  void previousPage(event) {
    var _currentItem = getNovelPageData(context, listen: false).currentItem;
    var readDirection = ConfigHelper.getNovelReadDirection();
    var _indexPage = getNovelPageData(context, listen: false).indexPage;

    if (_controller.page == 1) {
      previousChapter(1);
    } else {
      setState(() {
        var pageTo = _indexPage - 1;
        _controller.animateToPage(pageTo,
            duration: pageChangeDura, curve: curveWay);
        NovelHistoryProvider.updateOrCreate(NovelHistory(widget.novelId,
            _currentItem.chapter_id, _indexPage.toDouble(), readDirection));
        // ConfigHelper.setCurrentPage(
        //     widget.novelId, _currentItem.chapter_id, pageTo);
      });
    }
  }

  void nextChapter(event) async {
    var _currentItem = getNovelPageData(context, listen: false).currentItem;
    var readDirection = ConfigHelper.getNovelReadDirection();

    if (widget.chapters.indexOf(_currentItem) == widget.chapters.length - 1) {
      Fluttertoast.showToast(msg: '已经是最后一章了');
      return;
    }

    double page = 0;
    if (readDirection == 2) {
      page = 0;
    } else {
      // ConfigHelper.setCurrentPage(widget.novelId, _currentItem.chapter_id, 1);

      getNovelPageData(context, listen: false).changeIndexPage(1);
      page = 1;
    }
    NovelHistoryProvider.updateOrCreate(NovelHistory(
        widget.novelId, _currentItem.chapter_id, page, readDirection));

    setState(() {
      _currentItem = widget.chapters[widget.chapters.indexOf(_currentItem) + 1];
      getNovelPageData(context, listen: false).changeCurrentItem(_currentItem);
    });
    await loadData(1, toStart: true);
  }

  void previousChapter(event) async {
    var _currentItem = getNovelPageData(context, listen: false).currentItem;
    var readDirection = ConfigHelper.getNovelReadDirection();

    if (widget.chapters.indexOf(_currentItem) == 0) {
      Fluttertoast.showToast(msg: '已经是最前面一章了');
      return;
    }

    double page = 0;
    if (readDirection == 2) {
      page = 0;
    } else {
      // ConfigHelper.setCurrentPage(widget.novelId, _currentItem.chapter_id, 1);

      getNovelPageData(context, listen: false).changeIndexPage(1);
      page = 1;
    }
    NovelHistoryProvider.updateOrCreate(NovelHistory(
        widget.novelId, _currentItem.chapter_id, page, readDirection));

    setState(() {
      _currentItem = widget.chapters[widget.chapters.indexOf(_currentItem) - 1];
      getNovelPageData(context, listen: false).changeCurrentItem(_currentItem);
    });
    await loadData(1, toEnd: true);
  }

  void initEvent() {
    pagechangeEvent = mainEvent.on<ChangePage>().listen((event) {
      if (event.asc) {
        previousPage(1);
      } else {
        nextPage(1);
      }
    });

    eventRunnter = mainEvent.on<EventType>().listen((event) {
      var type = event.type;
      switch (type) {
        case eventType.loadData:
          loadData(1);
          break;
        case eventType.nextChapter:
          nextChapter(1);
          break;
        case eventType.previousChapter:
          previousChapter(1);
          break;
        case eventType.handleContent:
          handleContent(1);
          break;
        case eventType.jumpTo:
          jumpTo(event.page);
          break;
        case eventType.jumpToVer:
          jumpToVer(event.page);
          break;
        default:
      }
    });
  }

  void jumpToVer(double e) {
    _controllerVer.jumpTo(e);
  }

  void jumpTo(double e) {
    _controller.jumpToPage(e.toInt());
  }
}

class ComputeParameter {
  Uint8List content;
  double width;
  double height;
  double fontSize;
  double lineHeight;
  ComputeParameter(
      this.content, this.width, this.height, this.fontSize, this.lineHeight);
}

class ChangePage {
  bool asc;
  ChangePage(this.asc);
}
