import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/chapter.dart';

class ChapterTiles extends StatelessWidget {
  final List<Chapter> chapters;

  const ChapterTiles({Key? key, required this.chapters}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      itemCount: chapters.length,
      padding: const EdgeInsets.all(8.0),
      onReorder: (oldIndex, newIndex) {
        // Gérer la réorganisation ici si nécessaire
      },
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return Card(
          key: ValueKey(chapter.title),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          color: AppColors.current.containerBackground,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chapter.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.current.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  chapter.previewText,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.current.secondaryText,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
