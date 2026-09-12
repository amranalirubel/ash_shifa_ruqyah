class SubItem {
  final String title;
  final String description;

  const SubItem({required this.title, required this.description});
}

class ProblemModel {
  final String title;
  final List<SubItem> items;

  const ProblemModel({required this.title, required this.items});
}
