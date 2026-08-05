import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore course catalog document (`courses/{courseId}`).
class Course {
  const Course({
    required this.courseId,
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.thumbnail,
    required this.icon,
    required this.color,
    required this.isFree,
    required this.isPublished,
    required this.price,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String courseId;
  final String title;
  final String shortTitle;
  final String description;
  final String? thumbnail;
  final String? icon;
  final String? color;
  final bool isFree;
  final bool isPublished;
  final num price;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Course.fromFirestore(
    String courseId,
    Map<String, dynamic> data,
  ) {
    return Course(
      courseId: (data['courseId'] as String?) ?? courseId,
      title: (data['title'] as String?) ?? '',
      shortTitle: (data['shortTitle'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      thumbnail: data['thumbnail'] as String?,
      icon: data['icon'] as String?,
      color: data['color'] as String?,
      isFree: (data['isFree'] as bool?) ?? false,
      isPublished: (data['isPublished'] as bool?) ?? false,
      price: (data['price'] as num?) ?? 0,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: _readTimestamp(data['createdAt']),
      updatedAt: _readTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'shortTitle': shortTitle,
      'description': description,
      'thumbnail': thumbnail,
      'icon': icon,
      'color': color,
      'isFree': isFree,
      'isPublished': isPublished,
      'price': price,
      'sortOrder': sortOrder,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
