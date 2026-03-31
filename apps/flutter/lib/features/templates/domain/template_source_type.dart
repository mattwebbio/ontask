/// Source type for a template — whether it was created from a list or a section.
enum TemplateSourceType {
  list,
  section;

  /// Parses a [TemplateSourceType] from a JSON string value.
  static TemplateSourceType fromJson(String value) {
    switch (value) {
      case 'list':
        return TemplateSourceType.list;
      case 'section':
        return TemplateSourceType.section;
      default:
        throw ArgumentError('Unknown TemplateSourceType: $value');
    }
  }

  /// Converts this enum to its JSON string representation.
  String toJson() => name;
}
