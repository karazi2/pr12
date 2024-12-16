import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/api_service.dart'; // Подключаем ApiService для запросов

class CartPage extends StatefulWidget {
  final List<Note> cartItems;

  const CartPage({Key? key, required this.cartItems}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Подсчет общей стоимости товаров в корзине
  double _calculateTotalPrice() {
    return widget.cartItems.fold(0.0, (sum, item) => sum + item.price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Корзина')),
      body: Column(
        children: [
          Expanded(
            child: widget.cartItems.isEmpty
                ? const Center(child: Text('Корзина пуста'))
                : ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return ListTile(
                  leading: item.photo_id.isNotEmpty
                      ? Image.network(
                    item.photo_id,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported),
                  )
                      : const Icon(Icons.image_not_supported),
                  title: Text(item.title),
                  subtitle: Text('₽${item.price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle),
                    onPressed: () async {
                      try {
                        // Отправляем запрос на удаление элемента из корзины
                        await ApiService().removeFromCart(1, item.id); // Замените 1 на реальный userId

                        setState(() {
                          // Удаляем элемент локально после успешного запроса
                          widget.cartItems.removeAt(index);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Элемент удален из корзины')),
                        );
                        print('Элемент успешно удален из корзины');
                      } catch (e) {
                        print('Ошибка удаления из корзины: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ошибка удаления из корзины')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Общая стоимость:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₽${_calculateTotalPrice().toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
