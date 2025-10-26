import 'package:flutter/material.dart';
import '../../organisms/navbar.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(title: 'Notifications'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildNotificationCard(
                    'Success',
                    'Well done! You successfully read this important alert message.',
                    Colors.green,
                    Icons.check_circle,
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationCard(
                    'Info',
                    'This alert needs your attention, but it\'s not super important.',
                    Colors.blue,
                    Icons.info,
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationCard(
                    'Warning',
                    'Better check yourself, you\'re not looking too good.',
                    Colors.orange,
                    Icons.warning,
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationCard(
                    'Danger',
                    'Change a few things up and try submitting again.',
                    Colors.red,
                    Icons.error,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    String title,
    String message,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}