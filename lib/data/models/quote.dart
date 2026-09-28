import 'dart:convert';

class QuoteLine {
  final String id;
  final String name;
  final double unitPrice;
  final double quantity;

  const QuoteLine({
    required this.id,
    required this.name,
    required this.unitPrice,
    this.quantity = 1,
  });

  double get total => unitPrice * quantity;

  QuoteLine copyWith({
    String? id,
    String? name,
    double? unitPrice,
    double? quantity,
  }) =>
      QuoteLine(
        id: id ?? this.id,
        name: name ?? this.name,
        unitPrice: unitPrice ?? this.unitPrice,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };

  factory QuoteLine.fromMap(Map<String, dynamic> map) => QuoteLine(
        id: map['id'] as String,
        name: map['name'] as String,
        unitPrice: (map['unitPrice'] as num).toDouble(),
        quantity: (map['quantity'] as num? ?? 1).toDouble(),
      );

  String toJson() => jsonEncode(toMap());
  factory QuoteLine.fromJson(String source) =>
      QuoteLine.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class Quote {
  final String id;
  final String clientName;
  final String subject;
  final List<QuoteLine> lines;
  final double labour;
  final bool useSignature;
  final String templateId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? remoteId; // backend sync id

  const Quote({
    required this.id,
    required this.clientName,
    required this.subject,
    required this.lines,
    this.labour = 0,
    this.useSignature = false,
    this.templateId = 'classic',
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
  });

  double get linesTotal =>
      lines.fold(0, (sum, l) => sum + l.total);

  double get total => linesTotal + (labour > 0 ? labour : 0);

  Quote copyWith({
    String? id,
    String? clientName,
    String? subject,
    List<QuoteLine>? lines,
    double? labour,
    bool? useSignature,
    String? templateId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remoteId,
  }) =>
      Quote(
        id: id ?? this.id,
        clientName: clientName ?? this.clientName,
        subject: subject ?? this.subject,
        lines: lines ?? this.lines,
        labour: labour ?? this.labour,
        useSignature: useSignature ?? this.useSignature,
        templateId: templateId ?? this.templateId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        remoteId: remoteId ?? this.remoteId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientName': clientName,
        'subject': subject,
        'lines': jsonEncode(lines.map((l) => l.toMap()).toList()),
        'labour': labour,
        'useSignature': useSignature ? 1 : 0,
        'templateId': templateId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'remoteId': remoteId,
      };

  factory Quote.fromMap(Map<String, dynamic> map) {
    final linesRaw = map['lines'] as String?;
    List<QuoteLine> lines = [];
    if (linesRaw != null && linesRaw.isNotEmpty) {
      final decoded = jsonDecode(linesRaw) as List<dynamic>;
      lines = decoded
          .map((e) => QuoteLine.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return Quote(
      id: map['id'] as String,
      clientName: map['clientName'] as String,
      subject: map['subject'] as String,
      lines: lines,
      labour: (map['labour'] as num? ?? 0).toDouble(),
      useSignature: (map['useSignature'] as int? ?? 0) == 1,
      templateId: map['templateId'] as String? ?? 'classic',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          map['updatedAt'] as int),
      remoteId: map['remoteId'] as String?,
    );
  }
}
