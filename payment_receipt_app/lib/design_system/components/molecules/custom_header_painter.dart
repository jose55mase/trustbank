import 'package:flutter/material.dart';
import '../../colors/tb_colors.dart';

class CustomHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [TBColors.primary, TBColors.primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    
    // Crear forma ondulada en la parte inferior
    path.lineTo(0, size.height - 30);
    
    // Primera curva
    path.quadraticBezierTo(
      size.width * 0.25, 
      size.height - 10, 
      size.width * 0.5, 
      size.height - 20
    );
    
    // Segunda curva
    path.quadraticBezierTo(
      size.width * 0.75, 
      size.height - 30, 
      size.width, 
      size.height - 10
    );
    
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Agregar círculos decorativos
    final circlePaint = Paint()
      ..color = TBColors.white.withOpacity(0.1);
    
    canvas.drawCircle(Offset(size.width * 0.8, 30), 20, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.3), 15, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.6), 12, circlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}