class Chapter {
  final String title;
  final String content;
  final int index;
  final int chapterNumber;

  Chapter({
    required this.title,
    required this.content,
    required this.index,
    required this.chapterNumber,
  });

  @override
  String toString() {
    return 'Chapter{title: $title, index: $index, contentLength: ${content.length}}';
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'index': index,
      'chapterNumber': chapterNumber,
    };
  }

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      title: map['title'] as String,
      content: map['content'] as String,
      index: map['index'] as int,
      chapterNumber: map['chapterNumber'] as int,
    );
  }
}
