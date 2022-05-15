import 'package:flutter/material.dart';
import 'package:flutter_dmzj/models/novel/novel_volume_item.dart';

class NovelPageData with ChangeNotifier {
  NovelPageData() {
    changeLoading(false);
  }

  bool _loading;
  bool get loading => _loading;
  void changeLoading(bool value) {
    _loading = value;

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

    notifyListeners();
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
  bool showChapters = false;
  PageController controller = PageController(initialPage: 1);
  ScrollController controllerVer = ScrollController();

  int indexPage = 1;

  bool subscribe;
}
