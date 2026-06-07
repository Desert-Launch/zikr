import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/khatma/data/datasources/local/ds_local_khatma.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';
import 'package:quran/modules/khatma/presentation/cubits/cb_khatma.dart';

class SNKhatmaWirds extends StatefulWidget {
  const SNKhatmaWirds({super.key, required this.planId});

  final int planId;

  @override
  State<SNKhatmaWirds> createState() => _SNKhatmaWirdsState();
}

class _SNKhatmaWirdsState extends State<SNKhatmaWirds> {
  static const _green = Color(0xFF007A58);
  static const _canvas = Color(0xFFF8F7F4);
  static const _border = Color(0xFFDDE6E0);

  late final Future<_WirdsData?> _data = _load();

  Future<_WirdsData?> _load() async {
    final local = Modular.get<DSLocalKhatma>();
    final plan = await local.plan(widget.planId);
    if (plan == null) return null;
    return _WirdsData(plan, await local.wirds(plan));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: FutureBuilder<_WirdsData?>(
        future: _data,
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return Center(child: Text('common_error'.tr()));
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(onBack: Modular.to.pop)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 100.h),
                sliver: SliverList.list(
                  children: [
                    _SectionLabel('khatma_suggested'.tr()),
                    _SuggestedWird(
                      wird: data.wirds.first,
                      onTap: () => _openWird(data.wirds.first),
                    ),
                    SizedBox(height: 14.h),
                    _SectionLabel('khatma_all_wirds'.tr()),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          for (final wird in data.wirds) ...[
                            _WirdRow(wird: wird, onTap: () => _openWird(wird)),
                            if (wird != data.wirds.last)
                              const Divider(
                                height: 1,
                                indent: 12,
                                endIndent: 12,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<_WirdsData?>(
        future: _data,
        builder: (_, snapshot) {
          final data = snapshot.data;
          if (data == null) return const SizedBox.shrink();
          final cubit = Modular.get<CBKhatma>();
          final isCurrent =
              cubit.state.plan?.planId == data.plan.id &&
              cubit.state.hasActivePlan;
          return SafeArea(
            minimum: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 12.h),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                padding: EdgeInsets.symmetric(vertical: 13.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
              ),
              onPressed: () => _start(data.plan),
              child: Text(
                isCurrent
                    ? 'khatma_continue_plan'.tr()
                    : 'khatma_start_plan'.tr(),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openWird(MKhatmaWird wird) {
    Modular.to.pushNamed(QuranRoutes.readerFromPage(wird.startPageNumber));
  }

  Future<void> _start(MKhatmaMetadata plan) async {
    final cubit = Modular.get<CBKhatma>();
    if (cubit.state.hasActivePlan && cubit.state.plan?.planId == plan.id) {
      Modular.to.pushReplacementNamed(KhatmaRoutes.fullTracker());
      return;
    }
    if (cubit.state.hasActivePlan) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('khatma_replace_plan_title'.tr()),
          content: Text('khatma_replace_plan_body'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('common_cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('khatma_start_plan'.tr()),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }
    await cubit.startPlan(plan);
    if (!mounted) return;
    Modular.to.pushReplacementNamed(KhatmaRoutes.fullTracker());
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: _SNKhatmaWirdsState._green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'khatma_start_title'.tr(),
              style: TextStyle(color: Colors.white, fontSize: 20.sp),
            ),
            SizedBox(width: 8.w),
            IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedWird extends StatelessWidget {
  const _SuggestedWird({required this.wird, required this.onTap});

  final MKhatmaWird wird;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _SNKhatmaWirdsState._border),
        ),
        child: _WirdContent(wird: wird),
      ),
    );
  }
}

class _WirdRow extends StatelessWidget {
  const _WirdRow({required this.wird, required this.onTap});

  final MKhatmaWird wird;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        child: _WirdContent(wird: wird),
      ),
    );
  }
}

class _WirdContent extends StatelessWidget {
  const _WirdContent({required this.wird});

  final MKhatmaWird wird;

  @override
  Widget build(BuildContext context) {
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    final startSurah = isArabic ? wird.startSurahAr : wird.startSurahEn;
    final endSurah = isArabic ? wird.endSurahAr : wird.endSurahEn;
    return Row(
      children: [
        const Icon(Icons.chevron_left_rounded, size: 18),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${'khatma_wird_day'.tr()} ${wird.index}',
              style: TextStyle(fontSize: 15.sp),
            ),
            Text(
              '$startSurah ${wird.startAyahNumber} - '
              '$endSurah ${wird.endAyahNumber}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 5.w, bottom: 6.h),
      child: Text(
        text,
        textAlign: TextAlign.end,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
      ),
    );
  }
}

class _WirdsData {
  const _WirdsData(this.plan, this.wirds);

  final MKhatmaMetadata plan;
  final List<MKhatmaWird> wirds;
}
