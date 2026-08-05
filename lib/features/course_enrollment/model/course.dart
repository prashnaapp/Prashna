import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore course catalog document (`courses/{courseId}`).
class Course {
  const Course({
    required this.courseId,
    required this.title,
    required this.description,
    required this.isFree,
    required this.isPublished,
    required this.price,
    required this.thumbnail,
    required this.createdAt,
    required this.updatedAt,
  });

  final String courseId;
  final String title;
  final String description;
  final bool isFree;
  final bool isPublished;
  final num price;
  final String? thumbnail;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Course.fromFirestore(
    String courseId,
    Map<String, dynamic> data,
  ) {
    return Course(
      courseId: (data['courseId'] as String?) ?? courseId,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      isFree: (data['isFree'] as bool?) ?? false,
      isPublished: (data['isPublished'] as bool?) ?? false,
      price: (data['price'] as num?) ?? 0,
      thumbnail: data['thumbnail'] as String?,
      createdAt: _readTimestamp(data['createdAt']),
      updatedAt: _readTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'isFree': isFree,
      'isPublished': isPublished,
      'price': price,
      'thumbnail': thumbnail,
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
