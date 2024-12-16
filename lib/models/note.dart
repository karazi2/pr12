class Note {
  final int id;
  final String title;
  final String description;
  final String photo_id; // Поле для фото
  final double price;
  bool isFavorite;

  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.photo_id, // Исправлено
    required this.price,
    this.isFavorite = false,
  });


  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      photo_id: json['image_link'] as String,
      price: (json['price'] as num).toDouble(),
      isFavorite: json['favourite'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_link': photo_id,
      'price': price,
      'favourite': isFavorite,
    };
  }
}



