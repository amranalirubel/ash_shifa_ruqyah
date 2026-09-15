class StoreCategory {
  const StoreCategory._();

  static const grocery = 'মুদি';
  static const vegetable = 'সবজি';
  static const fishMeat = 'মাছ/মাংস';
  static const other = 'অন্যান্য';
  static const all = [grocery, vegetable, fishMeat, other];

  static const Map<String, String> aliases = {
    'পুঁই শাক': 'পুঁইশাক',
    'পুই শাক': 'পুঁইশাক',
    'পুইশাক': 'পুঁইশাক',
    'কাঁচা মরিচ': 'কাঁচামরিচ',
    'কাচামরিচ': 'কাঁচামরিচ',
    'ধনিয়া পাতা': 'ধনেপাতা',
    'ধনিয়া পাতা': 'ধনেপাতা',
    'ধনিয়া': 'ধনিয়া',
  };

  static const Map<String, String> productCategories = {
    'কাঁচামরিচ': vegetable,
    'পুঁইশাক': vegetable,
    'ধনেপাতা': vegetable,
    'ধনিয়া': vegetable,
    'আলু': vegetable,
    'পটল': vegetable,
    'বেগুন': vegetable,
    'পেঁয়াজ': vegetable,
    'পেয়াজ': vegetable,
    'টমেটো': vegetable,
    'লেবু': vegetable,
    'লাউ': vegetable,
    'শাক': vegetable,
    'কুমড়া': vegetable,
    'ঝিঙা': vegetable,
    'শসা': vegetable,
    'গাজর': vegetable,
    'তেল': grocery,
    'সাবান': grocery,
    'আঠা': grocery,
    'চিনি': grocery,
    'ডাল': grocery,
    'চাল': grocery,
    'আটা': grocery,
    'লবণ': grocery,
    'মসলা': grocery,
    'হলুদ': grocery,
    'দুধ': grocery,
    'বিস্কুট': grocery,
    'শ্যাম্পু': grocery,
    'ডিটারজেন্ট': grocery,
    'টিস্যু': grocery,
    'ডিম': grocery,
    'মাছ': fishMeat,
    'মুরগি': fishMeat,
    'মাংস': fishMeat,
    'গরুর মাংস': fishMeat,
  };

  static String guess(String name) {
    var normalized = name.toLowerCase().trim();
    for (final alias in aliases.entries) {
      normalized = normalized.replaceAll(alias.key, alias.value);
    }
    final ordered = productCategories.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final product in ordered) {
      if (normalized.contains(product)) return productCategories[product]!;
    }
    return other;
  }
}
