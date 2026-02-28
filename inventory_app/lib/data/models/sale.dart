import 'product.dart';
import 'user.dart';
import 'customer.dart';

class Sale {
  final String id;
  final List<Product> products;
  final double total;
  final DateTime date;
  final User? assignedUser;
  final Customer? customer;

  Sale({
    required this.id,
    required this.products,
    required this.total,
    required this.date,
    this.assignedUser,
    this.customer,
  });
}
