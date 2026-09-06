import 'package:flutter/foundation.dart';

import '../../authentication/services/user_session_state_coordinator.dart';
import '../data/models/question_activity_models.dart';
import '../data/question_activity_api.dart';

/// Session-scoped encounter index keyed by global [questionId].
///
/// Multiple encounters for the same question merge under one identity.
/// This store does **not** write `user_revision` or `user_bookmarks`; those
/// remain with Cloud Functions / BookmarkService respectively.
class QuestionActivityEncounterStore {
  QuestionActivityEncounterStore();

  final Map<String, List<QuestionActivityContext>> _byQuestionId = {};

  Map<String, List<QuestionActivityContext>> get snapshot {
    return Map.unmodifiable({
      for (final entry in _byQuestionId.entries)
        entry.key: List.unmodifiable(entry.value),
    });
  }

  List<QuestionActivityContext> encountersFor(String questionId) {
    final id = questionId.trim();
    if (id.isEmpty) return const [];
    return List.unmodifiable(_byQuestionId[id] ?? const []);
  }

  /// Global revision identities currently known to the session store.
  Set<String> get questionIds => Set.unmodifiable(_byQuestionId.keys);

  void record(QuestionActivityContext context) {
    recordIfNew(context);
  }

  /// Returns false when the encounter was a duplicate and not stored.
  bool recordIfNew(QuestionActivityContext context) {
    final id = context.questionId.trim();
    if (id.isEmpty) return false;
    final list = _byQuestionId.putIfAbsent(id, () => <QuestionActivityContext>[]);
    if (_isDuplicateEncounter(list, context)) return false;
    list.add(context);
    return true;
  }

  void clear() => _byQuestionId.clear();

  static bool _isDuplicateEncounter(
    List<QuestionActivityContext> existing,
    QuestionActivityContext next,
  ) {
    for (final prior in existing) {
      if (prior.sourceModule == next.sourceModule &&
          prior.sourceType == next.sourceType &&
          prior.testId == next.testId &&
          prior.encounterId == next.encounterId &&
          prior.courseId == next.courseId) {
        return true;
      }
    }
    return false;
  }
}

/// Single reporting boundary for question activity across independent modules.
///
/// Wrong-answer **authority** for Revision Center remains server-side:
/// - Catalog: `submitTestAttempt` → shared revision side effects
/// - Practice (H2.8F-3B): `reportQuestionActivity` → same shared revision merge
///
/// This reporter:
/// - records encounter context under one global question identity
/// - dispatches verified practice wrongs to the backend
/// - never writes `user_revision` from the client
/// - does not replace BookmarkService cloud sync
class QuestionActivityReporter {
  QuestionActivityReporter._({
    UserSessionStateCoordinator? sessionCoordinator,
    QuestionActivityEncounterStore? encounterStore,
    QuestionActivityApi? activityApi,
  }) : _sessions = sessionCoordinator ?? UserSessionStateCoordinator.instance,
       _encounters = encounterStore ?? QuestionActivityEncounterStore(),
       _api = activityApi ?? QuestionActivityApi() {
    _sessions.register(clear);
  }

  static final QuestionActivityReporter instance = QuestionActivityReporter._();

  final UserSessionStateCoordinator _sessions;
  final QuestionActivityEncounterStore _encounters;
  final QuestionActivityApi _api;
  final List<QuestionActivityEvent> _recentEvents = [];
  static const int _maxRecentEvents = 200;
  int _eventGeneration = 0;

  @visibleForTesting
  QuestionActivityReporter.debug({
    UserSessionStateCoordinator? sessionCoordinator,
    QuestionActivityEncounterStore? encounterStore,
    QuestionActivityApi? activityApi,
  }) : this._(
         sessionCoordinator: sessionCoordinator,
         encounterStore: encounterStore,
         activityApi: activityApi,
       );

  QuestionActivityEncounterStore get encounters => _encounters;

  List<QuestionActivityEvent> get recentEvents =>
      List.unmodifiable(_recentEvents);

  void clear() {
    _eventGeneration++;
    _encounters.clear();
    _recentEvents.clear();
  }

  /// Stable activity event id for one wrong answer within a practice session.
  ///
  /// Retries of the same submit must reuse the same [activitySessionId].
  static String activityEventIdFor({
    required String activitySessionId,
    required String questionId,
  }) {
    final session = activitySessionId.trim();
    final qid = questionId.trim();
    return 'qa_${session}_$qid';
  }

  /// Practice / revision practice may dispatch to verified activity callable.
  /// Current Affairs is blocked until durable question identity is proven.
  static bool shouldPersistVerifiedActivity(
    QuestionActivitySourceModule module,
  ) {
    return module == QuestionActivitySourceModule.practice ||
        module == QuestionActivitySourceModule.revision;
  }

  /// Reports incorrect answers for [contexts] into the session encounter index.
  void reportWrongAnswers({
    required List<QuestionActivityContext> contexts,
    required QuestionActivityAuthority authority,
    UserSessionIdentity? session,
  }) {
    final identity = session ?? _sessions.capture();
    if (!_sessions.isCurrent(identity)) return;

    for (final context in contexts) {
      if (!_sessions.isCurrent(identity)) return;
      final id = context.questionId.trim();
      if (id.isEmpty) continue;
      final stamped = context.recordedAt == null
          ? context.copyWith(recordedAt: DateTime.now())
          : context;
      if (!_encounters.recordIfNew(stamped)) continue;
      _append(
        QuestionActivityEvent(
          type: QuestionActivityType.wrongAnswer,
          context: stamped,
          authority: authority,
          isCorrect: false,
        ),
      );
    }
  }

  /// Local encounter + verified backend persistence for practice wrongs.
  ///
  /// Distinguishes LOCAL ACTIVITY RECORDED from SERVER AUTHORITATIVE PERSISTED.
  /// Does not claim success when the callable fails.
  Future<List<QuestionActivityPersistResult>> reportAndPersistWrongAnswers({
    required List<QuestionActivityWrongSubmission> submissions,
    UserSessionIdentity? session,
  }) async {
    final identity = session ?? _sessions.capture();
    if (!_sessions.isCurrent(identity)) {
      return [
        for (final item in submissions)
          QuestionActivityPersistResult(
            questionId: item.context.questionId,
            activityEventId: item.activityEventId,
            state: QuestionActivityPersistState.notDispatched,
            error: StateError('Session no longer current'),
          ),
      ];
    }

    final results = <QuestionActivityPersistResult>[];
    for (final item in submissions) {
      if (!_sessions.isCurrent(identity)) {
        results.add(
          QuestionActivityPersistResult(
            questionId: item.context.questionId,
            activityEventId: item.activityEventId,
            state: QuestionActivityPersistState.notDispatched,
            error: StateError('Session no longer current'),
          ),
        );
        continue;
      }

      final context = item.context.recordedAt == null
          ? item.context.copyWith(recordedAt: DateTime.now())
          : item.context;
      _encounters.recordIfNew(context);
      _append(
        QuestionActivityEvent(
          type: QuestionActivityType.wrongAnswer,
          context: context,
          authority: QuestionActivityAuthority.serverVerifiedQuestionOption,
          isCorrect: false,
        ),
      );

      if (!shouldPersistVerifiedActivity(context.sourceModule)) {
        results.add(
          QuestionActivityPersistResult(
            questionId: context.questionId,
            activityEventId: item.activityEventId,
            state: QuestionActivityPersistState.notDispatched,
          ),
        );
        continue;
      }

      try {
        final response = await _api.reportQuestionActivity(
          activityEventId: item.activityEventId,
          questionId: context.questionId,
          selectedOption: item.selectedOption,
          context: context,
        );
        if (!_sessions.isCurrent(identity)) {
          results.add(
            QuestionActivityPersistResult(
              questionId: context.questionId,
              activityEventId: item.activityEventId,
              state: QuestionActivityPersistState.serverFailed,
              error: StateError('Session changed during persist'),
            ),
          );
          continue;
        }
        final duplicate = response['duplicate'] == true;
        final revisionApplied = response['revisionApplied'] == true;
        final isWrong = response['isWrong'] == true;
        results.add(
          QuestionActivityPersistResult(
            questionId: context.questionId,
            activityEventId: item.activityEventId,
            state: (revisionApplied || (duplicate && isWrong))
                ? QuestionActivityPersistState.serverPersisted
                : QuestionActivityPersistState.localRecorded,
            duplicate: duplicate,
          ),
        );
      } catch (error, stack) {
        debugPrint(
          'QuestionActivityReporter persist failed '
          'qid=${context.questionId} event=${item.activityEventId}: $error',
        );
        assert(() {
          debugPrint('$stack');
          return true;
        }());
        results.add(
          QuestionActivityPersistResult(
            questionId: context.questionId,
            activityEventId: item.activityEventId,
            state: QuestionActivityPersistState.serverFailed,
            error: error,
          ),
        );
      }
    }
    return results;
  }

  void reportBookmarkAdded({
    required QuestionActivityContext context,
    UserSessionIdentity? session,
  }) {
    _reportBookmark(
      context: context,
      type: QuestionActivityType.bookmarkAdded,
      session: session,
    );
  }

  void reportBookmarkRemoved({
    required QuestionActivityContext context,
    UserSessionIdentity? session,
  }) {
    _reportBookmark(
      context: context,
      type: QuestionActivityType.bookmarkRemoved,
      session: session,
    );
  }

  void _reportBookmark({
    required QuestionActivityContext context,
    required QuestionActivityType type,
    UserSessionIdentity? session,
  }) {
    final identity = session ?? _sessions.capture();
    if (!_sessions.isCurrent(identity)) return;
    final id = context.questionId.trim();
    if (id.isEmpty) return;
    final stamped = context.recordedAt == null
        ? context.copyWith(recordedAt: DateTime.now())
        : context;
    _encounters.recordIfNew(stamped);
    _append(
      QuestionActivityEvent(
        type: type,
        context: stamped,
        authority: QuestionActivityAuthority.bookmarkCloud,
      ),
    );
  }

  void _append(QuestionActivityEvent event) {
    _recentEvents.add(event);
    if (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeRange(0, _recentEvents.length - _maxRecentEvents);
    }
  }

  @visibleForTesting
  int get debugEventGeneration => _eventGeneration;
}

/// One wrong answer ready for verified backend dispatch.
class QuestionActivityWrongSubmission {
  const QuestionActivityWrongSubmission({
    required this.activityEventId,
    required this.selectedOption,
    required this.context,
  });

  final String activityEventId;
  final String selectedOption;
  final QuestionActivityContext context;
}
