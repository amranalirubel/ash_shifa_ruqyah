import '../models/bazzer_item_model.dart';
import 'store_category.dart';

export 'bazzer_format.dart';

class BazzerDailyNote {
  BazzerDailyNote(this.day, Iterable<BazzerItem> source)
    : items = List.of(source)..sort(_compare);

  final String day;
  final List<BazzerItem> items;
  int get totalPaisa =>
      items.fold(0, (sum, item) => sum + (item.pricePaisa ?? 0));
  int get unpricedCount =>
      items.where((item) => item.pricePaisa == null).length;

  List<int> get runningTotals {
    var total = 0;
    return [for (final item in items) total += item.pricePaisa ?? 0];
  }

  static int _compare(BazzerItem a, BazzerItem b) {
    final store = StoreCategory.all
        .indexOf(a.category)
        .compareTo(StoreCategory.all.indexOf(b.category));
    if (store != 0) return store;
    final time = a.createdAt.compareTo(b.createdAt);
    if (time != 0) return time;
    return '${a.isSecure}/${a.id}'.compareTo('${b.isSecure}/${b.id}');
  }

  static List<BazzerDailyNote> group(Iterable<BazzerItem> items) {
    final days = <String, List<BazzerItem>>{};
    for (final item in items) {
      days.putIfAbsent(item.dayKey, () => []).add(item);
    }
    final keys = days.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final key in keys) BazzerDailyNote(key, days[key]!)];
  }
}
