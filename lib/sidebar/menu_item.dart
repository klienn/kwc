import 'package:flutter/material.dart';

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final GestureTapCallback onTap;

  const MenuItem(
      {super.key,
      required this.icon,
      required this.title,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              color: Color(0xff3B1002),
              size: 30,
            ),
            SizedBox(
              width: 20,
            ),
            // Wrap Text widget in Expanded to prevent overflow
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 26,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
