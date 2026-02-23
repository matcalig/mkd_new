class ResultValue {
  const ResultValue({
    required this.compound,
    required this.property,
    required this.status,
    required this.value,
    required this.units,
    this.reference = '',
  });

  final String compound;
  final String property;
  final String status;
  final String value;
  final String units;
  final String reference;
}
