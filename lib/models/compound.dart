class Compound {
  const Compound({required this.identifier, this.entityType = 'Chemical'});

  factory Compound.fromJson(Map<String, dynamic> json) {
    return Compound(
      identifier: json['Identifier'] as String? ?? '',
      entityType: json['EntityType'] as String? ?? 'Chemical',
    );
  }

  final String identifier;
  final String entityType;

  @override
  bool operator ==(Object other) =>
      other is Compound && other.identifier == identifier;

  @override
  int get hashCode => identifier.hashCode;

  @override
  String toString() => identifier;
}
