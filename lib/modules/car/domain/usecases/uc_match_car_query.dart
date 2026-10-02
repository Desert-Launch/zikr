import 'package:quran/modules/car/domain/entities/e_car_query_match.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';

/// Resolves a spoken or typed car query — "play Surah Al-Kahf by Alafasy",
/// «شغل سورة الكهف للعفاسي», "Quran radio Cairo" — into what to play.
///
/// Pure and offline: the caller passes the catalogues in. Matching is by
/// whole words after folding away what speech-to-text and typing vary on:
/// Arabic diacritics and letter variants (أ/إ/آ → ا, ة → ه, ى → ي), the
/// definite article (ال / al-), filler words ("play", «سورة»), and a one-letter
/// slip in longer Latin words ("rehman" for "rahman").
class UCMatchCarQuery {
  const UCMatchCarQuery();

  /// Matches for [query], best first. Empty when nothing matched.
  List<ECarQueryMatch> call(
    String query, {
    required List<MSurah> surahs,
    required List<MReciter> reciters,
    List<MRadioStation> stations = const [],
  }) {
    final words = _words(query);
    if (words.isEmpty) return const [];
    final queryTokens = <String>{
      for (final w in words)
        if (!_fillers.contains(w)) w,
    };
    final wantsRadio = words.any(_radioWords.contains);

    final matches = <ECarQueryMatch>[];

    if (wantsRadio && stations.isNotEmpty) {
      final ranked = _rank(
        stations,
        (s) => [s.name, s.nameEn ?? ''],
        queryTokens,
        everyNameWord: false,
      );
      // "Qur'an radio" with no station named → the first (national) one.
      final picked = ranked.isEmpty ? [stations.first] : ranked;
      matches.addAll([for (final s in picked) ECarStationMatch(s.id)]);
    }

    // The reciter first: their name may hold a surah's name («عبد الرحمن» has
    // «الرحمن» in it), so the words it used are not offered to the surahs.
    // Two guards keep a surah from being read as a reciter: the word right
    // after «سورة»/"surah" is the surah's, and a reciter matched only on
    // words that also name a surah («شغل الرحمن») is no reciter at all.
    final reservedForSurah = <String>{
      for (var i = 0; i + 1 < words.length; i++)
        if (_surahWords.contains(words[i])) words[i + 1],
    };
    final surahNameTokens = <String>{
      for (final s in surahs)
        for (final name in [s.arabic, s.name, s.translation]) ..._tokens(name),
    };
    var reciter = _bestReciter(
      reciters,
      queryTokens.difference(reservedForSurah),
    );
    if (reciter != null && reciter.usedTokens.every(surahNameTokens.contains)) {
      reciter = null;
    }
    final surahTokens = reciter == null
        ? queryTokens
        : queryTokens.difference(reciter.usedTokens);

    final rankedSurahs = _rank(
      surahs,
      (s) => [s.arabic, s.name, s.translation],
      surahTokens,
      everyNameWord: true,
    );
    final reciterId = reciter?.reciter.id;
    for (final s in rankedSurahs) {
      matches.add(ECarSurahMatch(surah: s.number, reciterId: reciterId));
    }

    // "Surah 18" / «سورة ١٨».
    if (rankedSurahs.isEmpty) {
      for (final t in surahTokens) {
        final n = int.tryParse(t);
        if (n != null && n >= 1 && n <= 114) {
          matches.add(ECarSurahMatch(surah: n, reciterId: reciterId));
          break;
        }
      }
    }

    if (reciter != null && !matches.any((m) => m is ECarSurahMatch)) {
      matches.add(ECarReciterMatch(reciter.reciter.id));
    }
    return matches;
  }

  // ---------------------------------------------------------------------------
  // Ranking
  // ---------------------------------------------------------------------------

  /// [items] whose names match [queryTokens], best first. With [everyNameWord]
  /// a name only matches when all of its words were said (surah names are
  /// short and precise); otherwise any of its words counts (station names are
  /// long and people say only the city).
  List<T> _rank<T>(
    List<T> items,
    List<String> Function(T) namesOf,
    Set<String> queryTokens, {
    required bool everyNameWord,
  }) {
    final scored = <(T, int)>[];
    for (final item in items) {
      var best = 0;
      for (final name in namesOf(item)) {
        final nameTokens = _tokens(name);
        if (nameTokens.isEmpty) continue;
        var score = 0;
        var all = true;
        for (final t in nameTokens) {
          final hit = _bestHit(t, queryTokens);
          if (hit == 0) {
            all = false;
          } else {
            score += hit;
          }
        }
        if (everyNameWord && !all) continue;
        if (score > best) best = score;
      }
      if (best > 0) scored.add((item, best));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final (item, _) in scored) item];
  }

  _ReciterHit? _bestReciter(List<MReciter> reciters, Set<String> queryTokens) {
    _ReciterHit? best;
    for (final r in reciters) {
      final used = <String>{};
      var score = 0;
      for (final name in [r.arabic, r.name]) {
        for (final t in _tokens(name)) {
          if (_commonNameWords.contains(t)) continue;
          for (final q in queryTokens) {
            if (_same(t, q)) {
              used.add(q);
              score += t.length;
            }
          }
        }
      }
      if (score == 0) continue;
      if (best == null || score > best.score) {
        best = _ReciterHit(r, score, used);
      }
    }
    return best;
  }

  /// How strongly [nameToken] was said: its length when said exactly, half
  /// that for a near miss, 0 when absent.
  int _bestHit(String nameToken, Set<String> queryTokens) {
    if (queryTokens.contains(nameToken)) return nameToken.length * 2;
    for (final q in queryTokens) {
      if (_near(nameToken, q)) return nameToken.length;
    }
    return 0;
  }

  bool _same(String a, String b) => a == b || _near(a, b);

  /// One edit apart, for words long enough that this cannot confuse two
  /// different names.
  bool _near(String a, String b) {
    if (a.length < 5 || b.length < 5) return false;
    if ((a.length - b.length).abs() > 1) return false;
    var i = 0;
    var j = 0;
    var edits = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        i++;
        j++;
        continue;
      }
      if (++edits > 1) return false;
      if (a.length > b.length) {
        i++;
      } else if (b.length > a.length) {
        j++;
      } else {
        i++;
        j++;
      }
    }
    return edits + (a.length - i) + (b.length - j) <= 1;
  }

  // ---------------------------------------------------------------------------
  // Normalisation
  // ---------------------------------------------------------------------------

  /// The words of a name, folded, minus fillers.
  List<String> _tokens(String text) => [
    for (final w in _words(text))
      if (!_fillers.contains(w)) w,
  ];

  /// [text] folded into comparable words (fillers included).
  List<String> _words(String text) {
    var s = text.toLowerCase();
    s = s.replaceAllMapped(
      RegExp('[٠-٩۰-۹]'),
      (m) => _digitValue(m.group(0) ?? '').toString(),
    );
    s = s
        .replaceAll(RegExp('[ً-ٰٟـ]'), '')
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ');
    return [
      for (final w in s.split(' '))
        if (w.isNotEmpty && !_articles.contains(w)) _fold(w),
    ];
  }

  static String _fold(String word) {
    var w = word;
    if (_isArabic(w)) {
      if (w.startsWith('ال') && w.length > 3) w = w.substring(2);
      // «للعفاسي», «لعبد» — a joined li- ("by/for").
      if (w.startsWith('لل') && w.length > 4) w = w.substring(2);
      return w;
    }
    if (w.startsWith('al') && w.length > 5) w = w.substring(2);
    if (w.endsWith('h') && w.length > 4) w = w.substring(0, w.length - 1);
    return w;
  }

  static bool _isArabic(String w) {
    final c = w.codeUnitAt(0);
    return c >= 0x0600 && c <= 0x06FF;
  }

  static int _digitValue(String digit) {
    final c = digit.codeUnitAt(0);
    return c >= 0x06F0 ? c - 0x06F0 : c - 0x0660;
  }

  /// Latin transliterations of the Arabic article, left standing alone by the
  /// hyphen in "Al-Kahf", "An-Nas", "Ash-Shams".
  /// Also the Arabic «آل» of «آل عمران», which folds to the bare article.
  static const Set<String> _articles = {
    'al', 'an', 'ar', 'as', 'at', 'ash', 'ad', 'adh', 'az', 'ath', 'el', 'ul',
    'ال',
  };

  /// Words that announce a surah name next. Stored folded.
  static const Set<String> _surahWords = {
    'سوره', 'سورت', 'surah', 'sura', 'surat', 'soora', 'chapter',
  };

  /// Words that carry no name: commands, "surah", "Qur'an", "by", "radio".
  /// Stored folded (article dropped, letters unified).
  static const Set<String> _fillers = {
    // Arabic
    'سوره', 'سورت', 'شغل', 'شغلي', 'تشغيل', 'اقرا', 'اسمع', 'اسمعني',
    'قران', 'قرءان', 'كريم', 'شيخ', 'للشيخ', 'قاري', 'بصوت', 'صوت', 'من',
    'علي', 'في', 'لي', 'الي', 'اذاعه', 'راديو', 'محطه', 'تلاوه',
    // English
    // ("sheik"/"soora": "sheikh"/"soorah" once a trailing h is folded away.)
    'surah', 'sura', 'surat', 'soora', 'chapter', 'play', 'please', 'the',
    'by', 'on', 'from', 'of', 'quran', 'koran', 'holy', 'recitation',
    'recited', 'reciter', 'sheik', 'shaik', 'shayk', 'radio', 'station',
    'zikr',
  };

  /// Words that ask for radio rather than a surah. Stored folded.
  static const Set<String> _radioWords = {
    'اذاعه', 'راديو', 'محطه', 'radio', 'station',
  };

  /// Parts of many reciters' names that single none of them out. (A style —
  /// «مجود», "teacher" — still counts: it picks between one voice's editions.)
  static const Set<String> _commonNameWords = {
    'عبد', 'محمد', 'بن', 'ابن', 'abd', 'abdul', 'abdu', 'muhammad',
    'mohammed', 'mohamed', 'bin', 'ibn',
  };
}

class _ReciterHit {
  const _ReciterHit(this.reciter, this.score, this.usedTokens);

  final MReciter reciter;
  final int score;

  /// Query words the reciter's name accounted for.
  final Set<String> usedTokens;
}
