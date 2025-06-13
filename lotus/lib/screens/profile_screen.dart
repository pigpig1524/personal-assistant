import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                'https://randomuser.me/api/portraits/women/44.jpg',
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Jane Doe',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              'junior.product.designer@example.com',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            Text(
              'Junior Product Designer',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}