import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

/// The gold gradient virtue card (سورة فاطر 29) shown at the bottom of the
/// adhan settings screens.
class WAdhanVirtueCard extends StatelessWidget {
  const WAdhanVirtueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 17.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF6DE), Color(0xFFF4DDA8)],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFD9B947), width: 1.4),
        boxShadow: const [
          BoxShadow(color: Color(0x16000000), blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: const Color(0xFFD9B947),
            child: Icon(Icons.star_rounded, color: Colors.white, size: 22.r),
          ),
          SizedBox(height: 8.h),
          Text(
            'khatma_virtue_title'.tr(),
            style: GoogleFonts.cairo(fontSize: 11.sp, color: const Color(0xFF8C7A55)),
          ),
          SizedBox(height: 10.h),
          Text(
            'إِنَّ الَّذِينَ يَتْلُونَ كِتَابَ اللَّهِ وَأَقَامُوا الصَّلَاةَ وَأَنفَقُوا مِمَّا رَزَقْنَاهُمْ سِرًّا وَعَلَانِيَةً يَرْجُونَ تِجَارَةً لَّن تَبُورَ',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 13.sp,
              height: 1.8,
              color: const Color(0xFF3E3522),
            ),
          ),
          Text(
            '[فاطر: 29]',
            style: GoogleFonts.cairo(fontSize: 10.sp, color: const Color(0xFF8C7A55)),
          ),
        ],
      ),
    );
  }
}
