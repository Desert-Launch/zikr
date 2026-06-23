import 'package:quran/modules/quran/domain/entities/e_tajweed_rule.dart';
import 'package:quran/modules/quran/domain/entities/e_tajweed_token.dart';

/// JSON shape of one pre-computed Tajweed token: `{ "t": "...", "r": "rule" }`
/// where `r` is `null` for plain text. See `assets/data/tajweed/page-*.json`.
class MTajweedToken {
  const MTajweedToken({required this.text, this.ruleKey});

  final String text;
  final String? ruleKey;

  factory MTajweedToken.fromJson(Map<String, dynamic> json) => MTajweedToken(
    text: json['t'] as String? ?? '',
    ruleKey: json['r'] as String?,
  );

  ETajweedToken toEntity() =>
      ETajweedToken(text: text, rule: ETajweedRule.fromKey(ruleKey));
}
