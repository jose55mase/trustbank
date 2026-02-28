import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/app_drawer.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = ['Electrónica', 'Ropa', 'Alimentos', 'Hogar', 'Deportes'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      drawer: const AppDrawer(currentRoute: '/categories'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.category, color: AppColors.primary),
              ),
              title: Text(categories[index], style: AppTextStyles.body),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('0 productos', style: AppTextStyles.caption),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              onTap: () {},
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }
}
