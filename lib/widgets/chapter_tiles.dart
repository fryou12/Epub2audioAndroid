import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ChapterTiles extends StatelessWidget {
  const ChapterTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth * 0.95,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(0, 0, 0, 0),
            border: Border.all(
              width: 1,
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            children: [
              // Chapter tiles will be added here
            ],
          ),
        );
      },
    );
  }
}
