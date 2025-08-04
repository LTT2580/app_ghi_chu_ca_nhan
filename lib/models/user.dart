class User {
  int? id;
  String? name;
  String? email;
  String? matkhau;
  String? avatar;

  User({
    this.id,
    this.name,
    this.email,
    this.matkhau,
    this.avatar,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'matkhau': matkhau,
      'avatar': avatar,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      matkhau: json['matkhau'],
      avatar: json['avatar'],
    );
  }

  // Thêm phương thức copyWith
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? matkhau,
    String? avatar,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      matkhau: matkhau ?? this.matkhau,
      avatar: avatar ?? this.avatar,
    );
  }
}