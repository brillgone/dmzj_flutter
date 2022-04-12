import 'package:sqflite/sqflite.dart';

final String tableName = 'novel_history';
//主键
final String columnNovelID = 'novel_id';
final String columnChapterID = 'chapter_id';
final String columnPage = 'page';
//1为横向，2为纵向阅读百分比
final String columnReadingMode = 'mode';

class NovelHistory {
  int novelId;
  int chapterId;
  double page;
  int mode;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnNovelID: novelId,
      columnChapterID: chapterId,
      columnPage: page,
      columnReadingMode: mode,
    };
    return map;
  }

  NovelHistory(this.novelId, this.chapterId, this.page, this.mode);

  NovelHistory.fromMap(Map<String, dynamic> map) {
    novelId = map[columnNovelID];
    chapterId = map[columnChapterID];
    page = map[columnPage];
    mode = map[columnReadingMode];
  }
}

class NovelHistoryProvider {
  static Database db;

  static void create(Database _db) {
    var batch = _db.batch();
    batch.execute('''
create table $tableName ( 
  $columnNovelID integer primary key not null, 
  $columnChapterID integer not null,
  $columnPage double not null,
  $columnReadingMode integer not null)
''');

    batch.commit();
    return;
  }

  static Future<NovelHistory> insert(NovelHistory item) async {
    await db.insert(tableName, item.toMap());

    return item;
  }

  static Future<NovelHistory> getItem(int id) async {
    List<Map> maps = await db.query(tableName,
        columns: [
          columnNovelID,
          columnChapterID,
          columnPage,
          columnReadingMode
        ],
        where: '$columnNovelID = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return NovelHistory.fromMap(maps.first);
    }
    return null;
  }

  static Future<int> clear() async {
    return await db.delete(tableName);
  }

  static Future<List<NovelHistory>> getItems() async {
    List<NovelHistory> maps = (await db.query(tableName))
        .map<NovelHistory>((x) => NovelHistory.fromMap(x))
        .toList();
    return maps;
  }

  static Future<int> delete(String id) async {
    return await db
        .delete(tableName, where: '$columnNovelID = ?', whereArgs: [id]);
  }

  static Future<int> update(NovelHistory item) async {
    return await db.update(tableName, item.toMap(),
        where: '$columnNovelID = ?', whereArgs: [item.novelId]);
  }

  static Future<bool> updateOrCreate(NovelHistory item) async {
    var isDone = false;
    getItem(item.novelId).then((historyItem) async {
      if (historyItem != null) {
        historyItem.chapterId = item.chapterId;
        historyItem.page = item.page.toDouble();
        historyItem.mode = item.mode;
        var ret = await update(historyItem);

        if (ret > 0) {
          isDone = true;
        }
      } else {
        var ret = await insert(NovelHistory(
            item.novelId, item.chapterId, item.page.toDouble(), 1));

        if (ret != null) {
          isDone = true;
        }
      }
      // Utils.changHistory.fire(widget.novelId);
    });

    return isDone;
  }

  static Future close() async => db.close();

  static Future<double> getPage(int id) async => (await getItem(id)).page;
}
