import 'package:flutter/material.dart';
import 'package:flutter_dmzj/models/novel/novel_volume_item.dart';
import 'package:flutter_dmzj/views/reader/novel_reader.dart';
import 'package:flutter_dmzj/views/reader/noval/novel_reader_page.dart';
import 'package:provider/provider.dart';
import 'package:event_bus/event_bus.dart';

// 获取当前小说页面共享数据
NovelPageData getNovelPageData(BuildContext context, {bool listen = true}) {
  return Provider.of<NovelPageData>(context, listen: listen);
}

class NovelPageData with ChangeNotifier {
  NovelPageData() {
    changeLoading(false);
  }

  bool loading = true;
  void changeLoading(bool value) {
    loading = value;

    notifyListeners();
  }

  List<String> _pageContents = ["加载中"];
  List<String> get pageContents => _pageContents;
  void changePageContents(List<String> value) {
    _pageContents = value;

    notifyListeners();
  }

  NovelVolumeChapterItem _currentItem;
  NovelVolumeChapterItem get currentItem => _currentItem;
  void changeCurrentItem(NovelVolumeChapterItem value) {
    _currentItem = value;

    // notifyListeners();
  }

  double _verSliderValue = 0;
  double get verSliderValue => _verSliderValue;
  void changeVerSliderValue(double value) {
    _verSliderValue = value;

    notifyListeners();
  }

  int _readDirection = 0;
  int get readDirection => _readDirection;
  void changeReadDirection(int value) {
    _readDirection = value;

    notifyListeners();
  }

  double verSliderMax = 0;

  bool showControls = false;
  void changeShowControls(bool value) {
    showControls = value;

    notifyListeners();
  }

  bool showChapters = false;
  void changeShowChapters(bool value) {
    showChapters = value;

    notifyListeners();
  }

  PageController controller = PageController(initialPage: 1);
  ScrollController controllerVer = ScrollController();

  int indexPage = 1;
  void changeIndexPage(int value) {
    indexPage = value;

    notifyListeners();
  }

  bool subscribe;
}

EventBus mainEvent = EventBus();

class EventType {
  eventType type;
  EventType(this.type);
}

enum eventType {
  loadData,
  nextChapter,
  previousChapter,
  handleContent,
}
