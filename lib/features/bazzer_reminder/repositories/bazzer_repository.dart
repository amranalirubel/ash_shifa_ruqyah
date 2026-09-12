import '../models/bazzer_item_model.dart';

class BazzerRepository {
  // 🔥 Firebase ready (পরে এই লাইনগুলো uncomment করবেন)
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // String familyId = "family_123"; // পরে auth থেকে আসবে

  final List<BazzerItem> _items = [];

  List<BazzerItem> getItems() => List.unmodifiable(_items);

  void addItem(BazzerItem item) {
    _items.add(item);
    // TODO: Firebase এ save করার কোড
    // _firestore.collection('families').doc(familyId).collection('bazar').add(item.toMap());
  }

  void addItems(List<BazzerItem> items) {
    _items.addAll(items);
  }

  void toggleItem(String id) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isBought: !_items[index].isBought);
    }
  }

  void removeItem(String id) {
    _items.removeWhere((e) => e.id == id);
  }

  void clearBoughtItems() {
    _items.removeWhere((e) => e.isBought);
  }

  // Firebase sync simulation (পরে ব্যবহার করবেন)
  // Future<void> syncFromFirebase() async { ... }
}
