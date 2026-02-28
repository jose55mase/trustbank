import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StockBadge extends StatelessWidget {
  final int stock;

  const StockBadge({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final config = _getStockConfig(stock);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: config.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  _StockConfig _getStockConfig(int stock) {
    if (stock == 0) {
      return _StockConfig('Sin Stock', AppColors.error);
    } else if (stock < 10) {
      return _StockConfig('Stock Bajo', AppColors.warning);
    } else {
      return _StockConfig('En Stock', AppColors.success);
    }
  }
}

class _StockConfig {
  final String label;
  final Color color;
  _StockConfig(this.label, this.color);
}
