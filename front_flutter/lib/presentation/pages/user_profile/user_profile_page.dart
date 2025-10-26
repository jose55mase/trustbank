import 'package:flutter/material.dart';
import '../../organisms/navbar.dart';
import '../../atoms/custom_text_field.dart';
import '../../atoms/custom_button.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(title: 'User Profile'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFF9C27B0),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mike Andrew',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'michael24',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Lamborghini Mercy, Your chick she so thirsty, I\'m in that two seat Lambo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Company',
                              hint: 'Creative Tim',
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              label: 'Username',
                              hint: 'michael23',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const CustomTextField(
                        label: 'Email address',
                        hint: 'mike@email.com',
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'First Name',
                              hint: 'Mike',
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              label: 'Last Name',
                              hint: 'Andrew',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Update Profile',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}