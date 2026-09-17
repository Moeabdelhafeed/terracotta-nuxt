import 'package:flutter/widgets.dart';

/// A single Help-center / FAQ entry.
@immutable
class FaqEntry {
  const FaqEntry({
    required this.id,
    required this.question,
    required this.answerMarkdown,
    required this.categoryId,
    this.tags = const <String>[],
    this.lastUpdated,
  });

  /// Stable identifier — used for deep-linking + recently-viewed
  /// persistence.
  final String id;
  final String question;

  /// Body rendered via `GlobalMarkdown`. Use full markdown — code
  /// fences / lists / links / images all supported.
  final String answerMarkdown;

  /// References [FaqCategory.id].
  final String categoryId;

  final List<String> tags;
  final DateTime? lastUpdated;

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'answer': answerMarkdown,
    'category': categoryId,
    if (tags.isNotEmpty) 'tags': tags,
    if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
  };

  factory FaqEntry.fromJson(Map<String, dynamic> json) => FaqEntry(
    id: json['id'] as String,
    question: json['question'] as String,
    answerMarkdown: (json['answer'] ?? json['answerMarkdown']) as String,
    categoryId: (json['category'] ?? json['categoryId']) as String,
    tags: (json['tags'] as List?)?.cast<String>() ?? const <String>[],
    lastUpdated: json['lastUpdated'] != null
        ? DateTime.tryParse(json['lastUpdated'] as String)
        : null,
  );
}

/// FAQ category — groups entries + drives the chip-filter row.
@immutable
class FaqCategory {
  const FaqCategory({
    required this.id,
    required this.name,
    this.icon,
    this.description,
  });

  final String id;
  final String name;
  final IconData? icon;
  final String? description;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
  };

  factory FaqCategory.fromJson(Map<String, dynamic> json) => FaqCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
  );
}

/// How entries are expanded when tapped.
enum FaqEntryVariant {
  /// Inline expand/collapse (ExpansionTile). Compact, keeps the
  /// user in the list.
  accordion,

  /// Push a full-screen detail route. Best for long answers.
  detailRoute,

  /// Open a bottom sheet with the answer. Mobile-friendly.
  bottomSheet,
}

/// Combined FAQ payload — categories + entries.
@immutable
class FaqData {
  const FaqData({
    required this.categories,
    required this.entries,
  });

  final List<FaqCategory> categories;
  final List<FaqEntry> entries;

  bool get isEmpty => entries.isEmpty;

  Map<String, dynamic> toJson() => {
    'categories': categories.map((c) => c.toJson()).toList(),
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  factory FaqData.fromJson(Map<String, dynamic> json) => FaqData(
    categories: (json['categories'] as List? ?? const [])
        .map((c) => FaqCategory.fromJson(c as Map<String, dynamic>))
        .toList(),
    entries: (json['entries'] as List? ?? const [])
        .map((e) => FaqEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static const empty = FaqData(categories: [], entries: []);
}

/// User feedback on whether an entry answered their question.
enum FaqFeedback { helpful, notHelpful }
