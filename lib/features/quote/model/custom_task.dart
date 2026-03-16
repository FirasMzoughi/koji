class CustomTask {
  final String id;
  final String title;
  final String? description;
  final String profession;
  final List<String> imageUrls;
  final Map<String, dynamic> defaultProducts;

  CustomTask({
    required this.id,
    required this.title,
    this.description,
    required this.profession,
    this.imageUrls = const [],
    this.defaultProducts = const {},
  });

  factory CustomTask.fromMap(Map<String, dynamic> map) {
    return CustomTask(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      profession: map['profession'] ?? '',
      imageUrls: List<String>.from(map['image_urls'] ?? []),
      defaultProducts: Map<String, dynamic>.from(map['default_products'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'profession': profession,
      'image_urls': imageUrls,
      'default_products': defaultProducts,
    };
  }
}
