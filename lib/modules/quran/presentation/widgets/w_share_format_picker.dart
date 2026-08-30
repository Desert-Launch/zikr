import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/entities/e_share_format.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_ayah_share.dart';
import 'package:quran/modules/quran/presentation/cubits/s_ayah_share.dart';
import 'package:quran/modules/quran/presentation/widgets/w_share_section.dart';

/// "Share as" — picture, text, or text with the harakat taken off.
class WShareFormatPicker extends StatelessWidget {
  const WShareFormatPicker({super.key});

  static const List<(EShareFormat, String)> _options = [
    (EShareFormat.image, 'quran_share_as_image'),
    (EShareFormat.text, 'quran_share_as_text'),
    (EShareFormat.plainText, 'quran_share_as_plain'),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<CBAyahShare>(context);
    return BlocSelector<CBAyahShare, SAyahShare, EShareFormat>(
      selector: (s) => s.format,
      builder: (context, format) => WShareSection(
        label: 'quran_share_as'.tr(),
        children: [
          for (final (option, key) in _options) ...[
            if (option != _options.first.$1) const WShareRowDivider(),
            WShareRow(
              title: key.tr(),
              onTap: () => cubit.setFormat(option),
              trailing: option == format
                  ? Icon(
                      Icons.check_rounded,
                      size: 20.r,
                      color: context.brand.primary,
                    )
                  : SizedBox(width: 20.r),
            ),
          ],
        ],
      ),
    );
  }
}
