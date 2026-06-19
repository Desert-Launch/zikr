import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/khatma/data/datasources/local/ds_local_khatma.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';
import 'package:quran/modules/khatma/presentation/cubits/cb_khatma.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_section_label.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_wird_row.dart';

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
    return WSharedScaffold(
      backgroundColor: _canvas,
      withSafeArea: false,
      padding: EdgeInsets.zero,
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
              SliverToBoxAdapter(
                child: WGradientAppBar(title: 'khatma_start_title'.tr()),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 100.h),
                sliver: SliverList.list(
                  children: [
                    WKhatmaSectionLabel('khatma_all_wirds'.tr()),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          for (final wird in data.wirds) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 5.h,
                                horizontal: 14.w,
                              ),
                              child: WKhatmaWirdRow(
                                wird: wird,
                                onTap: () => _openWird(wird),
                              ),
                            ),
                            if (wird != data.wirds.last)
                              const Divider(
                                height: 0.7,
                                indent: 24,
                                endIndent: 24,
                                color: _border,
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

class _WirdsData {
  const _WirdsData(this.plan, this.wirds);

  final MKhatmaMetadata plan;
  final List<MKhatmaWird> wirds;
}
