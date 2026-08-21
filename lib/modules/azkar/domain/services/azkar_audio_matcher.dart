import 'package:quran/core/utils/arabic_normalizer.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio.dart';

/// One of the app's existing adhkar — the thing audio gets attached *to*.
class AzkarMatchTarget {
  const AzkarMatchTarget({
    required this.adhkarId,
    required this.categoryId,
    required this.text,
    this.categoryName,
  });

  final String adhkarId;
  final String categoryId;
  final String? categoryName;
  final String text;
}

/// One record from an external audio source — the thing being attached.
class AzkarMatchCandidate {
  const AzkarMatchCandidate({
    required this.sourceId,
    required this.text,
    this.categoryName,
    this.audioUrl,
  });

  final String sourceId;
  final String text;
  final String? categoryName;
  final String? audioUrl;
}

/// Why the matcher decided what it decided. Written into the mapping report so
/// a human can audit every attachment without re-running the pipeline.
enum AzkarMatchReason {
  manualOverride,
  exactText,
  ambiguousResolvedByCategory,
  ambiguousUnresolved,
  fuzzyHigh,
  needsReview,
  temporalConflict,
  emptyText,
  noCandidate,
}

class AzkarMatchResult {
  const AzkarMatchResult({
    required this.target,
    required this.confidence,
    required this.reason,
    this.candidate,
    this.score = 0,
    this.runnerUp,
  });

  final AzkarMatchTarget target;
  final AzkarMatchCandidate? candidate;
  final EAzkarAudioMatch confidence;
  final AzkarMatchReason reason;
  final double score;

  /// Best rejected alternative, so an ambiguous decision can be reviewed.
  final AzkarMatchCandidate? runnerUp;

  /// Only accepted results become manifest entries.
  bool get isAccepted => candidate != null && confidence.isPlayable;
}

/// Attaches external audio records to the app's existing adhkar.
///
/// Deliberately conservative, in this order:
///   1. a hand-verified override always wins;
///   2. identical normalised Arabic → `exact`;
///   3. identical text matching several candidates → the one whose source
///      category reads closest to the app category, and only when that winner
///      is unambiguous → `high`;
///   4. fuzzy similarity above [highThreshold], clear of the runner-up by
///      [margin] → `high`;
///   5. anything between [reviewThreshold] and [highThreshold] is *reported,
///      never shipped*.
///
/// Across steps 3–5 a time-of-day conflict is an outright veto: morning and
/// evening adhkar are the same words with `أصبح…`/`أمسى…` swapped and score
/// ~0.9 against each other, so similarity alone would happily hand an evening
/// dhikr a recitation that says "morning".
class AzkarAudioMatcher {
  const AzkarAudioMatcher({
    this.manualOverrides = const <String, String>{},
    this.highThreshold = 0.92,
    this.margin = 0.03,
    this.reviewThreshold = 0.75,
  });

  /// `adhkarId` → external `sourceId`, hand-verified.
  final Map<String, String> manualOverrides;

  /// Fuzzy score at or above which a unique winner is accepted.
  final double highThreshold;

  /// How far ahead of the runner-up the winner must be.
  final double margin;

  /// Score below which a pair is not even worth a human's time.
  final double reviewThreshold;

  List<AzkarMatchResult> matchAll(
    List<AzkarMatchTarget> targets,
    List<AzkarMatchCandidate> candidates,
  ) {
    final byId = <String, AzkarMatchCandidate>{
      for (final c in candidates) c.sourceId: c,
    };
    final byText = <String, List<AzkarMatchCandidate>>{};
    for (final c in candidates) {
      final key = ArabicNormalizer.normalize(c.text);
      if (key.isEmpty) continue;
      byText.putIfAbsent(key, () => <AzkarMatchCandidate>[]).add(c);
    }
    return targets
        .map((t) => _matchOne(t, candidates, byId, byText))
        .toList(growable: false);
  }

  AzkarMatchResult _matchOne(
    AzkarMatchTarget target,
    List<AzkarMatchCandidate> candidates,
    Map<String, AzkarMatchCandidate> byId,
    Map<String, List<AzkarMatchCandidate>> byText,
  ) {
    // 1 — hand-verified override.
    final overrideId = manualOverrides[target.adhkarId];
    if (overrideId != null) {
      final hit = byId[overrideId];
      if (hit != null) {
        return AzkarMatchResult(
          target: target,
          candidate: hit,
          confidence: EAzkarAudioMatch.manual,
          reason: AzkarMatchReason.manualOverride,
          score: 1,
        );
      }
    }

    final key = ArabicNormalizer.normalize(target.text);
    if (key.isEmpty) {
      return AzkarMatchResult(
        target: target,
        confidence: EAzkarAudioMatch.unknown,
        reason: AzkarMatchReason.emptyText,
      );
    }

    // 2/3 — identical normalised text.
    final exact = byText[key];
    if (exact != null && exact.length == 1) {
      return AzkarMatchResult(
        target: target,
        candidate: exact.first,
        confidence: EAzkarAudioMatch.exact,
        reason: AzkarMatchReason.exactText,
        score: 1,
      );
    }
    if (exact != null && exact.length > 1) {
      return _disambiguate(target, exact);
    }

    // 4/5 — fuzzy.
    return _fuzzy(target, candidates);
  }

  /// Several candidates carry the *same* words (a dhikr the source repeats in
  /// two sittings). Pick by how closely the source's category name reads like
  /// the app's.
  ///
  /// A tie here is harmless in a way a fuzzy tie is not: every candidate's
  /// normalised text is *identical*, so each one is a recitation of exactly
  /// these words. When the category names cannot separate them we still take a
  /// deterministic winner — first in source order — and record it as `high`
  /// rather than `exact`, because the choice among equals was ours.
  AzkarMatchResult _disambiguate(
    AzkarMatchTarget target,
    List<AzkarMatchCandidate> tied,
  ) {
    final appCategory = target.categoryName ?? '';
    final scored =
        tied
            .map(
              (c) => (
                c: c,
                s: ArabicNormalizer.similarity(c.categoryName, appCategory),
              ),
            )
            .toList()
          ..sort((a, b) => b.s.compareTo(a.s));
    final best = scored.first;
    final second = scored.length > 1 ? scored[1] : null;
    final decisive = second == null || (best.s - second.s) >= margin;
    return AzkarMatchResult(
      target: target,
      candidate: decisive ? best.c : tied.first,
      confidence: EAzkarAudioMatch.high,
      reason: decisive
          ? AzkarMatchReason.ambiguousResolvedByCategory
          : AzkarMatchReason.ambiguousUnresolved,
      score: best.s,
      runnerUp: second?.c,
    );
  }

  AzkarMatchResult _fuzzy(
    AzkarMatchTarget target,
    List<AzkarMatchCandidate> candidates,
  ) {
    var bestScore = 0.0;
    AzkarMatchCandidate? best;
    var secondScore = 0.0;
    AzkarMatchCandidate? second;
    for (final c in candidates) {
      final s = ArabicNormalizer.similarity(target.text, c.text);
      if (s > bestScore) {
        secondScore = bestScore;
        second = best;
        bestScore = s;
        best = c;
      } else if (s > secondScore) {
        secondScore = s;
        second = c;
      }
    }
    if (best == null || bestScore < reviewThreshold) {
      return AzkarMatchResult(
        target: target,
        confidence: EAzkarAudioMatch.unknown,
        reason: AzkarMatchReason.noCandidate,
        score: bestScore,
      );
    }
    // Veto before anything else: a morning recitation is simply not this
    // evening dhikr, however similar the words are.
    if (ArabicNormalizer.hasTemporalConflict(target.text, best.text)) {
      return AzkarMatchResult(
        target: target,
        confidence: EAzkarAudioMatch.unknown,
        reason: AzkarMatchReason.temporalConflict,
        score: bestScore,
        runnerUp: best,
      );
    }
    if (bestScore >= highThreshold) {
      if ((bestScore - secondScore) >= margin) {
        return AzkarMatchResult(
          target: target,
          candidate: best,
          confidence: EAzkarAudioMatch.high,
          reason: AzkarMatchReason.fuzzyHigh,
          score: bestScore,
          runnerUp: second,
        );
      }
      // Two candidates score alike above the threshold, which means they read
      // alike to each other too — the classic case being a dhikr the source
      // prints in both its morning chapter and its bedtime chapter. Fall back
      // to the same category-name tie-break the exact path uses instead of
      // discarding a pair we are otherwise confident about.
      final contenders = candidates
          .where(
            (c) =>
                (bestScore - ArabicNormalizer.similarity(target.text, c.text)) <
                    margin &&
                !ArabicNormalizer.hasTemporalConflict(target.text, c.text),
          )
          .toList(growable: false);
      if (contenders.length > 1) return _disambiguate(target, contenders);
    }
    return AzkarMatchResult(
      target: target,
      confidence: EAzkarAudioMatch.unknown,
      reason: AzkarMatchReason.needsReview,
      score: bestScore,
      runnerUp: best,
    );
  }
}
