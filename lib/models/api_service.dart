import 'package:dio/dio.dart';
import 'note.dart';

class ApiService {
  final Dio _dio = Dio();

  // Получение всех квартир
  Future<List<Note>> getApartments() async {
    try {
      final response = await _dio.get('http://192.168.0.22:8080/apartments');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((apartment) => Note.fromJson(apartment))
            .toList();
      } else {
        throw Exception('Failed to load apartments');
      }
    } catch (e) {
      throw Exception('Error fetching apartments: $e');
    }
  }
  Future<Note> getApartmentById(int id) async {
    try {
      final response = await _dio.get('http://192.168.0.22:8080/apartments/$id');
      if (response.statusCode == 200) {
        return Note.fromJson(response.data); // Создаем объект Note из JSON
      } else {
        throw Exception('Failed to fetch apartment details');
      }
    } catch (e) {
      throw Exception('Error fetching apartment by ID: $e');
    }
  }
  Future<void> deleteApartment(int apartmentId) async {
    try {
      final response = await _dio.delete('http://192.168.0.22:8080/apartments/delete/$apartmentId');
      if (response.statusCode != 204) {
        throw Exception('Ошибка удаления квартиры');
      }
    } catch (e) {
      throw Exception('Ошибка удаления: $e');
    }
  }
  Future<void> createApartment(Note note) async {
    try {
      final data = {
        "title": note.title,
        "description": note.description,
        "image_link": note.photo_id,
        "price": note.price,
      };
      final response = await _dio.post('http://192.168.0.22:8080/apartments/create', data: data);

      if (response.statusCode != 200) {
        throw Exception('Ошибка создания квартиры: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка создания квартиры: $e');
    }
  }

  // Обновление информации о квартире
  Future<void> updateApartment(Note note) async {
    final data = {
      "ID": note.id,
      "Title": note.title,
      "Description": note.description,
      "ImageLink": note.photo_id,
      "Price": note.price,
    };

    try {
      final response = await _dio.put(
        'http://192.168.0.22:8080/apartments/update/${note.id}',
        data: data,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update apartment');
      }
    } catch (e) {
      throw Exception('Error updating apartment: $e');
    }
  }

  // Переключение избранного
  Future<void> toggleFavourite(int id) async {
    try {
      final response = await _dio.put(
        'http://192.168.0.22:8080/apartments/favourite/$id',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to toggle favourite');
      }
    } catch (e) {
      throw Exception('Error toggling favourite: $e');
    }
  }

  // Получение всех элементов корзины
  Future<List<CartItem>> getCart(int userId) async {
    try {
      final response = await _dio.get('http://192.168.0.22:8080/cart/$userId');
      if (response.statusCode == 200) {
        final cartData = (response.data as List).map((item) async {
          // Получаем данные квартиры для каждого элемента корзины
          final apartment = await getApartmentById(item['apartment_id'] as int);
          return CartItem(
            id: item['id'] as int,
            apartmentId: apartment.id,
            userId: item['user_id'] as int,
            title: apartment.title, // Используем данные квартиры
            price: apartment.price, // Используем данные квартиры
            quantity: item['quantity'] as int,
          );
        });

        return Future.wait(cartData); // Возвращаем собранный список
      } else {
        throw Exception('Ошибка загрузки корзины: статус ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки корзины: $e');
    }
  }


  // Добавление элемента в корзину
  Future<void> addToCart(int userId, int apartmentId) async {
    final data = {
      "user_id": userId,
      "apartment_id": apartmentId,
      "quantity": 1,
    };

    try {
      final response = await _dio.post(
        'http://192.168.0.22:8080/cart',
        data: data,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add item to cart');
      }
    } catch (e) {
      throw Exception('Error adding item to cart: $e');
    }
  }

  Future<void> removeFromCart(int userId, int apartmentId) async {
    try {
      final response = await _dio.delete(
        'http://192.168.0.22:8080/cart/$userId/$apartmentId',
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка удаления из корзины');
      }
    } catch (e) {
      throw Exception('Ошибка удаления: $e');
    }
  }

}
class CartItem {
  final int id;
  final int apartmentId;
  final int userId;
  final String title; // Название квартиры
  final double price; // Цена квартиры
  final int quantity;

  CartItem({
    required this.id,
    required this.apartmentId,
    required this.userId,
    required this.title,
    required this.price,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      apartmentId: json['apartment_id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String, // Добавьте название
      price: (json['price'] as num).toDouble(), // Добавьте цену
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apartment_id': apartmentId,
      'user_id': userId,
      'title': title,
      'price': price,
      'quantity': quantity,
    };
  }
}


