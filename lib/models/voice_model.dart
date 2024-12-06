class VoiceModel {
  final String id;
  final String name;
  final String language;
  final String? gender;

  VoiceModel({
    required this.id,
    required this.name,
    required this.language,
    this.gender,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          language == other.language &&
          gender == other.gender;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ language.hashCode ^ (gender?.hashCode ?? 0);

  @override
  String toString() {
    return 'VoiceModel{id: $id, name: $name, language: $language, gender: $gender}';
  }
}
