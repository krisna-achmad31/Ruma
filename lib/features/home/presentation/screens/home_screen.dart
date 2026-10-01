import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/family_scope.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

final _weatherRepository = WeatherRepositoryImpl();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyScope<HomeViewModel>(
      create: (user) => HomeViewModel(
        homeRepository: buildHomeRepository(),
        taskRepository: buildTaskRepository(),
        togetherRepository: buildTogetherRepository(),
        financeRepository: buildFinanceRepository(),
        settingsRepository: buildSettingsRepository(),
        weatherRepository: _weatherRepository,
        familyId: user.familyId,
        uid: user.uid,
        userName: user.name,
      ),
      child: const _HomeContent(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final now = DateTime.now();

    return AppScaffold(
      tab: AppTab.today,
      children: [
        LargeTitle(
          title: tr('Hari ini'),
          subtitle: '${greetingFor(now)}, ${vm.firstName}',
          subtitleAbove: true,
          trailing: Row(
            spacing: 8,
            children: [
              GlassCircleButton(icon: AppIcons.search, size: 42, onTap: () => context.push('/search')),
              GlassCircleButton(icon: AppIcons.bell, size: 42, badge: vm.unreadCount > 0, onTap: () => context.push('/notifications')),
            ],
          ),
        ),
        _ContextChips(vm: vm, now: now),
        _PartnerCard(vm: vm),
        _SafeToSpendCard(vm: vm),
        _Priorities(vm: vm),
        _TogetherWeek(vm: vm),
        const _QuickAdd(),
      ],
    );
  }
}

class _ContextChips extends StatelessWidget {
  final HomeViewModel vm;
  final DateTime now;

  const _ContextChips({required this.vm, required this.now});

  @override
  Widget build(BuildContext context) {
    final hasCity = (vm.family?.location ?? '').isNotEmpty;
    final chips = <(IconData, String)>[
      if (vm.weather != null) (AppIcons.cloudSun, vm.weather!.label),
      hasCity ? (AppIcons.mapPin, vm.family!.location) : (AppIcons.mapPin, tr('Atur kota untuk cuaca')),
      (AppIcons.calendar, '${shortDayNamesId[now.weekday - 1]}, ${formatShortDate(now)}'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        spacing: 8,
        children: chips
            .map((c) => GlassCard(
                  onTap: c.$1 == AppIcons.mapPin ? () => context.push('/settings/profile') : null,
                  radius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Row(spacing: 5, children: [
                    Icon(c.$1, size: 13, color: AppColors.muted),
                    Text(c.$2, style: AppText.body(12, weight: FontWeight.w600, color: AppColors.muted)),
                  ]),
                ))
            .toList(),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final HomeViewModel vm;

  const _PartnerCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final c = vm.partnerCheckIn;
    if (vm.partner == null) {
      return GlassCard(
        onTap: () => context.push('/invite'),
        padding: const EdgeInsets.all(16),
        child: Row(
          spacing: 14,
          children: [
            const IconBox(icon: AppIcons.userPlus, color: AppColors.rose, background: AppColors.roseSoft, size: 48),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Text(tr('Ajak pasanganmu'), style: AppText.body(16, weight: FontWeight.w700)),
                  Text(tr('Rumah tangga lebih ringan kalau dipikul berdua.'), style: AppText.body(13, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(AppIcons.chevronRight, size: 16, color: AppColors.faint),
          ],
        ),
      );
    }
    return GlassCard(
      onTap: () => context.go('/together'),
      padding: const EdgeInsets.all(16),
      child: Row(
        spacing: 14,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.roseSoft, borderRadius: BorderRadius.circular(16)),
            child: c == null ? const Icon(AppIcons.heart, color: AppColors.rose, size: 22) : Text(c.emoji, style: const TextStyle(fontSize: 24)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text(
                  c == null ? tr('{0} belum check-in', [vm.partnerName]) : '${vm.partnerName} ${_moodPhrase(c.mood)}',
                  style: AppText.body(16, weight: FontWeight.w700),
                ),
                Text(
                  c == null ? tr('Tanya kabarnya sebentar, dua menit cukup.') : (c.need.isEmpty ? tr('Belum menulis kebutuhan hari ini.') : '“${c.need}”'),
                  style: AppText.body(13, color: AppColors.muted, height: 1.35),
                ),
              ],
            ),
          ),
          if (c != null)
            Column(
              spacing: 4,
              children: [
                Text('${c.energy}/5', style: AppText.display(17, color: c.energy <= 2 ? AppColors.rose : AppColors.jade)),
                Text(tr('energi'), style: AppText.body(10, weight: FontWeight.w600, color: AppColors.muted)),
              ],
            ),
        ],
      ),
    );
  }

  static String _moodPhrase(int mood) => [tr('lagi berat'), tr('lagi capek'), tr('biasa aja'), tr('lagi baik'), tr('lagi senang')][mood.clamp(0, 4)];
}

class _SafeToSpendCard extends StatelessWidget {
  final HomeViewModel vm;

  const _SafeToSpendCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final hasBudget = vm.budgetTotal > 0;
    return HeroCard(
      colors: AppColors.jadeGradient,
      onTap: () => context.go('/finance'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Row(
            children: [
              Expanded(child: Text(tr('Aman dipakai hari ini'), style: AppText.body(14, weight: FontWeight.w600, color: const Color(0xCCFFFFFF)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x40FFFFFF)),
                ),
                child: Text(tr('{0} hari ke gajian', [vm.daysToPayday]), style: AppText.body(11, weight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
          Text(hasBudget ? formatRupiah(vm.safeToSpendToday) : tr('Rp0'), style: AppText.display(44, color: Colors.white, letterSpacing: -1.5)),
          ProgressBar(value: vm.budgetRemainingFraction, color: Colors.white, track: const Color(0x2EFFFFFF), height: 8),
          Text(
            hasBudget
                ? tr('Dari semua amplop. Sisa {0} untuk {1} hari.', [formatRupiahShort(vm.budgetRemaining), vm.daysToPayday])
                : tr('Buat amplop dulu supaya angka ini bisa dihitung.'),
            style: AppText.body(12, color: const Color(0xB3FFFFFF)),
          ),
        ],
      ),
    );
  }
}

class _Priorities extends StatelessWidget {
  final HomeViewModel vm;

  const _Priorities({required this.vm});

  @override
  Widget build(BuildContext context) {
    final items = vm.priorities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SectionHeader(
          title: tr('Perlu dipikirkan'),
          trailing: Row(
            spacing: 8,
            children: [
              Pill(tr('{0}/{1} beres', [vm.weekDone, vm.weekTotal])),
              GestureDetector(
                onTap: () => context.go('/urusan?add=1'),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                  child: const Icon(AppIcons.plus, size: 15, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        ListCard(
          children: items.isEmpty
              ? [EmptyNote(tr('Belum ada urusan minggu ini. Tambah dengan tombol +.'))]
              : items.map((t) => _PriorityRow(task: t, vm: vm)).toList(),
        ),
      ],
    );
  }
}

class _PriorityRow extends StatelessWidget {
  final TaskEntity task;
  final HomeViewModel vm;

  const _PriorityRow({required this.task, required this.vm});

  @override
  Widget build(BuildContext context) {
    final label = task.dueDate == null ? '' : relativeDayLabel(task.dueDate!);
    final color = label == tr('Hari ini') || label == tr('Kemarin')
        ? AppColors.rose
        : label == 'Besok'
            ? AppColors.amber
            : AppColors.jade;
    final soft = color == AppColors.rose ? AppColors.roseSoft : (color == AppColors.amber ? AppColors.amberSoft : AppColors.jadeSoft);
    return ListRow(
      icon: iconFor(task.icon),
      iconColor: color,
      iconBackground: soft,
      title: task.title,
      subtitle: vm.roleLine(task),
      trailingText: label,
      trailingColor: color,
      onTap: () => vm.toggleTask(task),
    );
  }
}

class _TogetherWeek extends StatelessWidget {
  final HomeViewModel vm;

  const _TogetherWeek({required this.vm});

  @override
  Widget build(BuildContext context) {
    final thanks = vm.latestThanksFromPartner;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            children: [
              Expanded(child: Text(tr('Minggu ini berdua'), style: AppText.body(15, weight: FontWeight.w700))),
              Text(tr('{0} urusan beres', [vm.doneThisWeek]), style: AppText.body(12, weight: FontWeight.w700, color: AppColors.jade)),
            ],
          ),
          if (vm.partnerOpenLoad >= 3)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.roseSoft, borderRadius: BorderRadius.circular(16)),
              child: Row(
                spacing: 12,
                children: [
                  Avatar(name: vm.partnerName, color: AppColors.rose),
                  Expanded(
                    child: Text(
                      tr('{0} lagi pegang {1} urusan, termasuk yang nggak kelihatan. Mau bantu satu?', [vm.partnerName, vm.partnerOpenLoad]),
                      style: AppText.body(13, height: 1.35),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/urusan'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(14)),
                      child: Text(tr('Bantu'), style: AppText.body(12, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(tr('Urusan minggu ini masih terasa ringan. Pertahankan saling bantunya.'), style: AppText.body(13, color: AppColors.muted)),
          if (thanks != null)
            Row(
              spacing: 8,
              children: [
                const Icon(AppIcons.heartHandshake, size: 16, color: AppColors.jade),
                Expanded(child: Text(tr('{0} bilang {1}', [thanks.authorName.split(' ').first, thanks.title.toLowerCase()]), style: AppText.body(12, color: AppColors.muted))),
              ],
            ),
        ],
      ),
    );
  }
}

class _QuickAdd extends StatefulWidget {
  const _QuickAdd();

  @override
  State<_QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<_QuickAdd> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    final message = await context.read<HomeViewModel>().quickAdd(text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (message.endsWith('tercatat.')) _controller.clear();
    showSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      strong: true,
      radius: 27,
      padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
      child: Row(
        spacing: 10,
        children: [
          const Icon(AppIcons.sparkles, size: 18, color: AppColors.amber),
          Expanded(
            child: TextField(
              controller: _controller,
              style: AppText.body(14),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: tr('beli sayur 45rb pakai gopay…'),
                hintStyle: AppText.body(14, color: AppColors.faint),
              ),
            ),
          ),
          GestureDetector(
            onTap: _busy ? null : _submit,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
              child: _busy
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(AppIcons.plus, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
