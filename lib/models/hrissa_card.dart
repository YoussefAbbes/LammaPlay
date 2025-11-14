/// Model for Hrissa Card game cards
class HrissaCard {
  final int id;
  final String category;
  final String question;
  final String difficulty;
  final int spicyLevel;

  HrissaCard({
    required this.id,
    required this.category,
    required this.question,
    required this.difficulty,
    required this.spicyLevel,
  });

  factory HrissaCard.fromJson(Map<String, dynamic> json) {
    return HrissaCard(
      id: json['id'] as int,
      category: json['category'] as String,
      question: json['question'] as String,
      difficulty: json['difficulty'] as String,
      spicyLevel: json['spicyLevel'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'difficulty': difficulty,
      'spicyLevel': spicyLevel,
    };
  }
}

/// Category metadata for Hrissa Cards
class HrissaCategory {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String colorLight;

  HrissaCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.colorLight,
  });

  factory HrissaCategory.fromJson(Map<String, dynamic> json) {
    return HrissaCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      colorLight: json['colorLight'] as String,
    );
  }
}
