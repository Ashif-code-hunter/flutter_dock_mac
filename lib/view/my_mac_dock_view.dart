import 'package:flutter/material.dart';
import 'package:mac_dock/view/widgets/dock.dart';

/// This widget creates a centered dock interface with animated icons that can be
/// reordered through drag and drop interactions. The dock features smooth scaling
/// animations when hovering over icons and fluid reordering animations.

class MyMacDock extends StatelessWidget {
  const MyMacDock({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Dock(
                    items: const [
                      Icons.person,
                      Icons.message,
                      Icons.call,
                      Icons.camera,
                      Icons.photo,
                    ],
                    builder: (e) {
                      return Icon(e, color: Colors.white);
                    },
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