import 'package:flutter/material.dart';
import '../models/chapter.dart';

class ChapterList extends StatelessWidget {
  final List<Chapter> chapters;
  final Function(Chapter)? onChapterTap;

  const ChapterList({
    super.key,
    required this.chapters,
    this.onChapterTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(
              chapter.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${chapter.wordCount} mots',
                  style: TextStyle(
                    color: Colors.grey[400],
                  ),
                ),
                Text(
                  chapter.previewText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
            onTap: onChapterTap != null ? () => onChapterTap!(chapter) : null,
          ),
        );
      },
    );
  }
}
