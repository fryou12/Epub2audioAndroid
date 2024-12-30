class Chapter {
  final String title;
  final String content;
  final int index;
  final bool isProcessing;
  final String audioPath;

  Chapter({
    required this.title,
    required this.content,
    required this.index,
    this.isProcessing = false,
    this.audioPath = '',
  });

  int get wordCount => content.split(' ').length;

  String get previewText {
    final words = content.split(' ');
    if (words.length <= 50) return content;
    return '${words.take(50).join(' ')}...';
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'index': index,
    'isProcessing': isProcessing,
    'audioPath': audioPath,
  };
}
