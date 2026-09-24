int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String _asString(dynamic value, [String fallback = '']) {
  if (value is String) return value;
  return fallback;
}

class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: _asInt(json['postId']),
      id: _asInt(json['id']),
      name: _asString(json['name']),
      email: _asString(json['email']),
      body: _asString(json['body']),
    );
  }

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };
}