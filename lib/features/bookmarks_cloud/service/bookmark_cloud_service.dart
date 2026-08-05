import '../model/bookmark_cloud.dart';
import '../repository/bookmark_cloud_repository.dart';

/// App-facing API for cloud bookmark documents.
///
/// Phase A: infrastructure only — not wired to local [BookmarkService] yet.
class BookmarkCloudService {
  BookmarkCloudService({
    BookmarkCloudRepository? repository,
  }) : _repository = repository ?? BookmarkCloudRepository();

  static final BookmarkCloudService instance = BookmarkCloudService();

  final BookmarkCloudRepository _repository;

  Future<BookmarkCloud?> load(String uid) => _repository.load(uid);

  Future<void> createIfMissing(String uid) =>
      _repository.createIfMissing(uid);

  Future<void> update(BookmarkCloud bookmarks) =>
      _repository.update(bookmarks);
}
